//! Native bcrypt and Furnace JWT adapter for the application token port.
use furnace_rs::prelude::*;
use rand::RngCore;
use serde::{Deserialize, Serialize};
use std::{
    ffi::{CStr, CString},
    sync::Mutex,
};
use tracker_application::{AppResult, DomainError, TokenCodec, TokenIdentity, TokenPair};
use uuid::Uuid;

#[link(name = "crypt")]
unsafe extern "C" {
    fn crypt(key: *const libc::c_char, salt: *const libc::c_char) -> *mut libc::c_char;
    fn crypt_gensalt_rn(
        prefix: *const libc::c_char,
        count: libc::c_ulong,
        rbytes: *const libc::c_char,
        nrbytes: libc::c_int,
        output: *mut libc::c_char,
        output_size: libc::c_int,
    ) -> *mut libc::c_char;
}
static CRYPT_LOCK: Mutex<()> = Mutex::new(());
pub struct Passwords;
impl Passwords {
    fn compute(password: &str, salt: &str) -> AppResult<String> {
        let p = CString::new(password).map_err(|_| DomainError::Unauthorized)?;
        let s = CString::new(salt).map_err(|_| DomainError::Unauthorized)?;
        let _lock = CRYPT_LOCK.lock().map_err(|_| DomainError::Unavailable)?;
        // SAFETY: C strings live through the call; crypt's static buffer is serialized
        // by CRYPT_LOCK and copied before unlocking. Null and failure markers are checked.
        let ptr = unsafe { crypt(p.as_ptr(), s.as_ptr()) };
        if ptr.is_null() {
            return Err(DomainError::Unavailable);
        }
        let result = unsafe { CStr::from_ptr(ptr) }
            .to_str()
            .map_err(|_| DomainError::Unavailable)?
            .to_owned();
        if !result.starts_with("$2") {
            return Err(DomainError::Unavailable);
        }
        Ok(result)
    }
    pub fn hash(password: &str) -> AppResult<String> {
        let mut random = [0u8; 16];
        rand::thread_rng().fill_bytes(&mut random);
        let mut salt = [0i8; 128];
        // SAFETY: all input/output lengths match allocated buffers; prefix is NUL terminated.
        let ptr = unsafe {
            crypt_gensalt_rn(
                c"$2b$".as_ptr(),
                12,
                random.as_ptr().cast(),
                16,
                salt.as_mut_ptr(),
                128,
            )
        };
        if ptr.is_null() {
            return Err(DomainError::Unavailable);
        }
        let s = unsafe { CStr::from_ptr(salt.as_ptr()) }
            .to_str()
            .map_err(|_| DomainError::Unavailable)?;
        Self::compute(password, s)
    }
    pub fn verify(password: &str, hash: &str) -> AppResult<bool> {
        if password.len() > 72
            || hash.len() != 60
            || !["$2a$", "$2b$", "$2y$"].iter().any(|p| hash.starts_with(p))
        {
            return Ok(false);
        }
        let actual = Self::compute(password, hash)?;
        let different = actual
            .as_bytes()
            .iter()
            .zip(hash.as_bytes())
            .fold(0u8, |a, (b, c)| a | (b ^ c));
        Ok(actual.len() == hash.len() && different == 0)
    }
}
#[derive(Serialize, Deserialize)]
struct Claims {
    user_id: Uuid,
    session_id: Uuid,
}
#[derive(Clone)]
pub struct Tokens {
    jwt: JwtService,
}
impl Tokens {
    /// Explicit constructor for tests and non-Furnace consumers.
    pub fn new(secret: String) -> AppResult<Self> {
        let config = ConfigBuilder::new()
            .source(furnace_rs::core::MapSource::new(
                "token-adapter",
                [("passport.secret", secret)],
            ))
            .build()
            .map_err(|_| DomainError::Unavailable)?;
        let jwt = JwtService::from_config(&config)
            .map_err(|_| DomainError::Validation("Invalid token signing configuration".into()))?;
        Ok(Self { jwt })
    }
    fn verify(&self, token: &str, validation: JwtValidation) -> AppResult<TokenIdentity> {
        let verified = self
            .jwt
            .verify::<Claims>(token, validation.require_subject())
            .map_err(|_| DomainError::Unauthorized)?;
        let registered = &verified.claims.registered;
        let custom = &verified.claims.custom;
        if registered.subject.as_deref() != Some(custom.user_id.to_string().as_str())
            || registered.issued_at > (chrono::Utc::now().timestamp() + 5) as u64
        {
            return Err(DomainError::Unauthorized);
        }
        Ok(TokenIdentity {
            user_id: custom.user_id,
            session_id: custom.session_id,
            expires_at: i64::try_from(registered.expires_at)
                .map_err(|_| DomainError::Unauthorized)?,
        })
    }
}
impl Injector<std::sync::Arc<dyn TokenCodec>> for Tokens {
    type Dependencies = (JwtService,);
    async fn inject(
        (jwt,): Self::Dependencies,
    ) -> furnace_rs::core::Result<std::sync::Arc<dyn TokenCodec>> {
        Ok(std::sync::Arc::new(Self { jwt }))
    }
}
impl TokenCodec for Tokens {
    fn issue(&self, user: Uuid, session: Uuid) -> AppResult<TokenPair> {
        use std::time::Duration;
        let sign = |options| {
            self.jwt
                .sign(
                    Claims {
                        user_id: user,
                        session_id: session,
                    },
                    options,
                )
                .map_err(|_| DomainError::Unavailable)
        };
        Ok(TokenPair {
            access: sign(
                JwtSignOptions::access(Duration::from_secs(600)).subject(user.to_string()),
            )?,
            refresh: sign(
                JwtSignOptions::refresh(Duration::from_secs(30 * 86400)).subject(user.to_string()),
            )?,
        })
    }
    fn verify_access(&self, token: &str) -> AppResult<TokenIdentity> {
        self.verify(token, JwtValidation::access())
    }
    fn verify_refresh(&self, token: &str) -> AppResult<TokenIdentity> {
        self.verify(token, JwtValidation::refresh())
    }
}

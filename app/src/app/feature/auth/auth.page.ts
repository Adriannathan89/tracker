import { Component, ChangeDetectorRef, inject, signal } from "@angular/core";
import { FormBuilder, ReactiveFormsModule, Validators } from "@angular/forms";
import { UserAuthService } from "../../core/service/user/user-auth.service";
import { UserRegisterService } from "../../core/service/user/user-register.service";
import { Router } from "@angular/router";
import { MatSnackBar } from "@angular/material/snack-bar";

@Component({
  standalone: true,
  imports: [ReactiveFormsModule],
  styles: [`
    :host { display: block; height: 100vh; }
    .bw-input {
      width: 100%; font-family: inherit; font-size: 15px;
      padding: 14px 16px; border-radius: 12px;
      background: var(--bw-elevated); color: var(--bw-ink);
      border: 1px solid var(--bw-border); outline: none;
      transition: border-color .12s, background .12s;
    }
    .bw-input:focus { border-color: var(--bw-ink); background: var(--bw-surface); }
    .bw-input::placeholder { color: var(--bw-ink-3); }
    .bw-label { font-size: 13px; font-weight: 600; color: var(--bw-ink-2); margin-bottom: 6px; display: block; }
    .tab-pill {
      flex: 1; padding: 9px 0; border-radius: 8px; font-size: 14px; font-weight: 600;
      cursor: pointer; transition: background .15s, color .15s; border: none;
      background: transparent; color: var(--bw-ink-3);
    }
    .tab-pill.active { background: var(--bw-ink); color: var(--bw-on-ink); }
    .deco-circle {
      position: absolute; width: 280px; height: 280px; border-radius: 50%;
      background: var(--bw-lime); opacity: 0.13; right: -80px; top: -80px;
      pointer-events: none;
    }
    .deco-circle-sm {
      position: absolute; width: 180px; height: 180px; border-radius: 50%;
      background: var(--bw-lime); opacity: 0.07; left: -50px; bottom: -50px;
      pointer-events: none;
    }
  `],
  template: `
    <div class="flex h-screen overflow-hidden" style="background:var(--bw-bg)">

      <!-- ─ Desktop: left ink panel ─ -->
      <div class="hidden md:flex flex-col justify-between relative overflow-hidden shrink-0"
           style="width:520px;background:var(--bw-ink);padding:56px 48px">
        <div class="deco-circle"></div>
        <div class="deco-circle-sm"></div>

        <div class="relative z-10">
          <!-- Logo -->
          <div class="mb-14">
            <img src="tracker-logo-on-dark.svg" alt="tracker" class="h-8 w-auto" />
          </div>

          <!-- Eyebrow -->
          <div class="text-[11px] font-bold tracking-[0.16em] uppercase mb-4"
               style="color:var(--bw-lime)">Catat &amp; Tagih</div>

          <!-- Headline -->
          <h2 class="text-[44px] font-extrabold leading-[1.1] tracking-[-0.03em]"
              style="color:var(--bw-on-ink)">
            Kelola utang<br>
            tanpa yang<br>
            <span style="color:var(--bw-lime)">ribet.</span>
          </h2>

          <p class="mt-6 text-[15px] leading-relaxed" style="color:var(--bw-ink-3)">
            Catat transaksi, lacak hutang piutang,<br>
            dan tagih teman dengan mudah.
          </p>
        </div>

        <!-- Footer -->
        <div class="relative z-10 text-[12px]" style="color:var(--bw-ink-3)">
          v2.0 · 2026 · Made in Jakarta 🇮🇩
        </div>
      </div>

      <!-- ─ Right: form panel ─ -->
      <div class="flex flex-col flex-1 overflow-y-auto">

        <!-- Mobile top band -->
        <div class="flex md:hidden flex-col items-center justify-center relative overflow-hidden px-6 py-10"
             style="background:var(--bw-ink)">
          <div style="position:absolute;width:200px;height:200px;border-radius:50%;background:var(--bw-lime);opacity:0.15;right:-50px;top:-50px;pointer-events:none"></div>
          <div class="flex items-center gap-2 mb-5 relative z-10">
            <div class="w-9 h-9 rounded-[10px] flex items-center justify-center font-black text-[16px]"
                 style="background:var(--bw-lime);color:var(--bw-ink)">B</div>
            <span class="text-[16px] font-bold" style="color:var(--bw-on-ink)">tracker</span>
          </div>
          <h2 class="text-[26px] font-extrabold tracking-[-0.03em] text-center relative z-10 leading-tight"
              style="color:var(--bw-on-ink)">
            Kelola utang tanpa yang<br>
            <span style="color:var(--bw-lime)">ribet.</span>
          </h2>
        </div>

        <!-- Form -->
        <div class="flex flex-1 items-center justify-center px-6 py-10">
          <div class="w-full max-w-[400px] animate-fade-slide-up">

            <!-- Tab toggle -->
            <div class="flex gap-1 p-1 rounded-[12px] mb-8" style="background:var(--bw-elevated)">
              <button type="button" class="tab-pill" [class.active]="isLogin"
                      (click)="switchTab(true)">Masuk</button>
              <button type="button" class="tab-pill" [class.active]="!isLogin"
                      (click)="switchTab(false)">Daftar</button>
            </div>

            <h1 class="text-[28px] font-extrabold tracking-[-0.03em] mb-1.5" style="color:var(--bw-ink)">
              {{ isLogin ? 'Halo lagi 👋' : 'Buat akun baru' }}
            </h1>
            <p class="text-[14px] mb-8" style="color:var(--bw-ink-3)">
              {{ isLogin ? 'Masukkan detail akunmu untuk lanjut.' : 'Isi form di bawah untuk mendaftar.' }}
            </p>

            <form [formGroup]="authForm" (ngSubmit)="handleSubmit()"
                  class="flex flex-col gap-4"
                  [class.animate-shake]="hasError">

              <div>
                <label class="bw-label">Username</label>
                <input class="bw-input" type="text" placeholder="username kamu"
                       formControlName="username" autocomplete="username" />
              </div>

              <div>
                <label class="bw-label">Password</label>
                <input class="bw-input" type="password" placeholder="••••••••"
                       formControlName="password"
                       [attr.autocomplete]="isLogin ? 'current-password' : 'new-password'" />
              </div>

              @if (!isLogin) {
                <div>
                  <label class="bw-label">Ulangi Password</label>
                  <input class="bw-input" type="password" placeholder="••••••••"
                         formControlName="repeatPassword" autocomplete="new-password" />
                </div>
              }

              <button type="submit"
                [disabled]="isSubmitting() || !canSubmit"
                class="mt-2 py-4 rounded-[12px] text-[15px] font-semibold transition cursor-pointer disabled:opacity-50"
                style="background:var(--bw-ink);color:var(--bw-on-ink)">
                {{ isSubmitting() ? 'Memproses…' : (isLogin ? 'Masuk →' : 'Daftar →') }}
              </button>

            </form>

          </div>
        </div>

      </div>

    </div>
  `
})
export class AuthPage {
  private fb = inject(FormBuilder);
  private registerService = inject(UserRegisterService);
  private authService = inject(UserAuthService);
  private router = inject(Router);
  private snackBar = inject(MatSnackBar);
  private cdr = inject(ChangeDetectorRef);

  isLogin = true;
  hasError = false;
  isSubmitting = signal(false);

  authForm = this.fb.nonNullable.group({
    username: ['', [Validators.required, Validators.minLength(3)]],
    password: ['', [Validators.required, Validators.minLength(6)]],
    repeatPassword: ['']
  });

  get canSubmit() {
    return this.authForm.valid && (
      this.isLogin || this.authForm.value.password === this.authForm.value.repeatPassword
    );
  }

  switchTab(login: boolean) {
    this.isLogin = login;
    this.authForm.reset();
  }

  async handleSubmit() {
    if (this.authForm.invalid) return;
    const { username, password } = this.authForm.value;

    if (this.isLogin) {
      try {
        this.isSubmitting.set(true);
        const success = await this.authService.login(String(username), String(password));
        if (success) {
          localStorage.setItem('username', String(username));
          this.router.navigate(['/dashboard']);
        }
      } catch {
        this.triggerError('Login gagal. Periksa username dan password kamu.');
      } finally {
        this.isSubmitting.set(false);
        this.cdr.detectChanges();
      }
    } else {
      try {
        this.isSubmitting.set(true);
        const success = await this.registerService.register(String(username), String(password));
        if (success) {
          this.snackBar.open('Akun berhasil dibuat! Silakan masuk.', 'Tutup', { duration: 3000 });
          this.switchTab(true);
        }
      } catch {
        this.triggerError('Pendaftaran gagal. Coba lagi.');
      } finally {
        this.isSubmitting.set(false);
        this.cdr.detectChanges();
      }
    }
  }

  private triggerError(msg: string) {
    this.hasError = true;
    this.snackBar.open(msg, 'Tutup', { duration: 3000 });
    setTimeout(() => { this.hasError = false; this.cdr.detectChanges(); }, 500);
  }
}

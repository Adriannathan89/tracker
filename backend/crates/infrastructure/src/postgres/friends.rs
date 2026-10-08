use super::*;
#[async_trait]
impl FriendRepository for PgStore {
    async fn search_friends(&self, user: Uuid, name: String) -> AppResult<Vec<Friend>> {
        if name.len() > 100 {
            return Err(DomainError::Validation("Search too long".into()));
        }
        // Prefix search treats wildcard characters literally.
        let prefix = format!(
            "{}%",
            name.replace('\\', "\\\\")
                .replace('%', "\\%")
                .replace('_', "\\_")
        );
        self.database.query_all_raw(statement("SELECT u.id,u.username,COALESCE(f.status,'not_friend') AS status FROM users u LEFT JOIN friendships f ON f.user_id=$1 AND f.friend_id=u.id WHERE u.id<>$1 AND u.username ILIKE $2 ORDER BY u.username LIMIT 50", vec![(user).into(), (prefix).into()])).await.map_err(db_error)?.iter().map(|r|Ok(Friend{id:value(r,"id")?,username:value(r,"username")?,status:value(r,"status")?})).collect()
    }
    async fn list_friends(&self, user: Uuid) -> AppResult<Vec<Friend>> {
        self.database.query_all_raw(statement("SELECT u.id,u.username,f.status FROM friendships f JOIN users u ON u.id=f.friend_id WHERE f.user_id=$1 AND f.status='accepted' ORDER BY u.username", vec![(user).into()])).await.map_err(db_error)?.iter().map(|r|Ok(Friend{id:value(r,"id")?,username:value(r,"username")?,status:value(r,"status")?})).collect()
    }
    async fn requests(&self, user: Uuid) -> AppResult<Vec<FriendRequest>> {
        self.database.query_all_raw(statement("SELECT q.*,s.username AS sender_name,r.username AS receiver_name FROM friend_requests q JOIN users s ON s.id=q.sender_id JOIN users r ON r.id=q.receiver_id WHERE q.receiver_id=$1 ORDER BY q.id", vec![(user).into()])).await.map_err(db_error)?.iter().map(|r|Ok(FriendRequest{id:value(r,"id")?,sender:UserSummary{id:value(r,"sender_id")?,username:value(r,"sender_name")?},receiver:UserSummary{id:value(r,"receiver_id")?,username:value(r,"receiver_name")?}})).collect()
    }
    async fn send_request(&self, user: Uuid, friend: Uuid) -> AppResult<()> {
        if user == friend {
            return Err(DomainError::Validation("Cannot add yourself".into()));
        }
        let tx = self.database.begin().await.map_err(db_error)?;
        lock_users(&tx, user, friend).await?;
        let exists=tx.query_one_raw(statement("SELECT 1 FROM friendships WHERE (user_id=$1 AND friend_id=$2) OR (user_id=$2 AND friend_id=$1)", vec![(user).into(), (friend).into()])).await.map_err(db_error)?.is_some();
        if exists {
            return Err(DomainError::Conflict(
                "Friendship or request already exists".into(),
            ));
        }
        tx.execute_raw(statement(
            "INSERT INTO friend_requests(id,sender_id,receiver_id) VALUES($1,$2,$3)",
            vec![(Uuid::new_v4()).into(), (user).into(), (friend).into()],
        ))
        .await
        .map_err(db_error)?;
        tx.execute_raw(statement(
            "INSERT INTO friendships(user_id,friend_id,status) VALUES($1,$2,'pending')",
            vec![(user).into(), (friend).into()],
        ))
        .await
        .map_err(db_error)?;
        tx.commit().await.map_err(db_error)?;
        Ok(())
    }
    async fn respond(&self, user: Uuid, id: Uuid, action: FriendAction) -> AppResult<()> {
        let tx = self.database.begin().await.map_err(db_error)?;
        // Read endpoints first, then lock users in the same order used by send_request.
        let initial = required(
            &tx,
            statement(
                "SELECT sender_id,receiver_id FROM friend_requests WHERE id=$1",
                vec![(id).into()],
            ),
        )
        .await
        .map_err(db_error)?;
        let sender: Uuid = value(&initial, "sender_id")?;
        let receiver: Uuid = value(&initial, "receiver_id")?;
        if user != receiver {
            return Err(DomainError::Forbidden);
        }
        lock_users(&tx, sender, receiver).await?;
        required(
            &tx,
            statement(
                "SELECT id FROM friend_requests WHERE id=$1 FOR UPDATE",
                vec![(id).into()],
            ),
        )
        .await
        .map_err(db_error)?;
        match action {
            FriendAction::Accept => {
                tx.execute_raw(statement(
                    "UPDATE friendships SET status='accepted' WHERE user_id=$1 AND friend_id=$2",
                    vec![(sender).into(), (receiver).into()],
                ))
                .await
                .map_err(db_error)?;
                tx.execute_raw(statement("INSERT INTO friendships(user_id,friend_id,status) VALUES($1,$2,'accepted') ON CONFLICT(user_id,friend_id) DO UPDATE SET status='accepted'", vec![(receiver).into(), (sender).into()])).await.map_err(db_error)?;
            }
            FriendAction::Reject => {
                tx.execute_raw(statement("DELETE FROM friendships WHERE user_id=$1 AND friend_id=$2 AND status='pending'", vec![(sender).into(), (receiver).into()])).await.map_err(db_error)?;
            }
        }
        tx.execute_raw(statement(
            "DELETE FROM friend_requests WHERE id=$1",
            vec![(id).into()],
        ))
        .await
        .map_err(db_error)?;
        tx.commit().await.map_err(db_error)?;
        Ok(())
    }
}

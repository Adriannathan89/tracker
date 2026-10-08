CREATE TABLE users (
 id UUID PRIMARY KEY, username TEXT NOT NULL UNIQUE, password TEXT NOT NULL,
 cash NUMERIC(20,2) NOT NULL DEFAULT 0, debt NUMERIC(20,2) NOT NULL DEFAULT 0 CHECK(debt>=0),
 receivable NUMERIC(20,2) NOT NULL DEFAULT 0 CHECK(receivable>=0),
 discord_id TEXT UNIQUE, discord_username TEXT,
 commit_notif BOOLEAN NOT NULL DEFAULT TRUE, weekly_notif BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE TABLE sessions (id UUID PRIMARY KEY,user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,expires_at TIMESTAMPTZ NOT NULL);
CREATE INDEX sessions_user ON sessions(user_id);
CREATE TABLE categories (id UUID PRIMARY KEY,name TEXT NOT NULL,kind TEXT NOT NULL CHECK(kind IN ('primary','secondary')),UNIQUE(name,kind));
CREATE TABLE records (
 id UUID PRIMARY KEY,owner_id UUID NOT NULL REFERENCES users(id),title TEXT NOT NULL,description TEXT NOT NULL DEFAULT '',
 amount NUMERIC(20,2) NOT NULL CHECK(amount>0),kind TEXT NOT NULL CHECK(kind IN ('income','expense')),
 created_at TIMESTAMPTZ NOT NULL,is_committed BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE INDEX records_owner ON records(owner_id,created_at);
CREATE TABLE record_categories(record_id UUID NOT NULL REFERENCES records(id) ON DELETE CASCADE,category_id UUID NOT NULL REFERENCES categories(id),PRIMARY KEY(record_id,category_id));
CREATE TABLE debts (
 id UUID PRIMARY KEY,owner_id UUID NOT NULL REFERENCES users(id),debtor_id UUID NOT NULL REFERENCES users(id),
 amount NUMERIC(20,2) NOT NULL CHECK(amount>0),description TEXT NOT NULL,
 status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','completed')),created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),CHECK(owner_id<>debtor_id)
);
CREATE INDEX debts_owner ON debts(owner_id);
CREATE INDEX debts_debtor ON debts(debtor_id,status);
CREATE TABLE friendships(user_id UUID NOT NULL REFERENCES users(id),friend_id UUID NOT NULL REFERENCES users(id),status TEXT NOT NULL CHECK(status IN ('pending','accepted')),PRIMARY KEY(user_id,friend_id),CHECK(user_id<>friend_id));
CREATE TABLE friend_requests(id UUID PRIMARY KEY,sender_id UUID NOT NULL REFERENCES users(id),receiver_id UUID NOT NULL REFERENCES users(id),CHECK(sender_id<>receiver_id));
CREATE UNIQUE INDEX friend_request_pair ON friend_requests(LEAST(sender_id,receiver_id),GREATEST(sender_id,receiver_id));
CREATE TABLE classifier_feedback(record_id UUID PRIMARY KEY REFERENCES records(id),title TEXT NOT NULL,category TEXT NOT NULL,secondary_category TEXT NOT NULL,source TEXT NOT NULL DEFAULT 'manual',created_at TIMESTAMPTZ NOT NULL DEFAULT NOW());
CREATE TABLE discord_verifications(user_id UUID PRIMARY KEY REFERENCES users(id),code TEXT NOT NULL UNIQUE CHECK(code ~ '^[0-9]{6}$'),expires_at TIMESTAMPTZ NOT NULL);
CREATE TABLE notification_outbox(id UUID PRIMARY KEY,user_id UUID NOT NULL REFERENCES users(id),kind TEXT NOT NULL CHECK(kind IN ('commit','weekly')),body TEXT NOT NULL,attempts INTEGER NOT NULL DEFAULT 0,available_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),delivered_at TIMESTAMPTZ,lease_until TIMESTAMPTZ);
CREATE TABLE report_deliveries(user_id UUID NOT NULL REFERENCES users(id),week_key TEXT NOT NULL,PRIMARY KEY(user_id,week_key));
INSERT INTO categories(id,name,kind) VALUES('6d90baf6-bebf-5036-83f8-118f52896526','makanan','primary');
INSERT INTO categories(id,name,kind) VALUES('6cf791cf-d3c5-5583-92be-1e42ebdbc7f8','minuman','primary');
INSERT INTO categories(id,name,kind) VALUES('6c9f91fa-c66d-5007-9831-8d7bcd2d8869','transport','primary');
INSERT INTO categories(id,name,kind) VALUES('806755b2-9a6d-5b08-aa14-0946c154e6b0','belanja','primary');
INSERT INTO categories(id,name,kind) VALUES('2e788c22-c9ec-5939-bd0e-b94e68c9ef7c','hiburan','primary');
INSERT INTO categories(id,name,kind) VALUES('80ae3ee5-f49d-56f9-9d65-4b3ae1e3931f','tagihan','primary');
INSERT INTO categories(id,name,kind) VALUES('a051410d-3868-57ea-b666-48e861b892a2','kesehatan','primary');
INSERT INTO categories(id,name,kind) VALUES('19b6ef29-9b32-5e99-8c93-b9ae3f43cb59','gaji','primary');
INSERT INTO categories(id,name,kind) VALUES('a678a14c-13b5-5970-bd0e-2cb1752ebe2d','hadiah','primary');
INSERT INTO categories(id,name,kind) VALUES('41600ada-1de1-52b7-96af-cef9020f83b7','jajanan','secondary');
INSERT INTO categories(id,name,kind) VALUES('61e7aa2b-f3d9-57bd-b6cc-26f02b4b5316','makanan','secondary');
INSERT INTO categories(id,name,kind) VALUES('5492a3ea-6120-56c8-b76b-05e8b7137221','minuman','secondary');
INSERT INTO categories(id,name,kind) VALUES('fb26126e-b236-5122-95d2-6846aa7e64d2','elektronik','secondary');
INSERT INTO categories(id,name,kind) VALUES('4dc46b00-dfa0-5a6d-807b-d7c6736b4a6a','fashion','secondary');
INSERT INTO categories(id,name,kind) VALUES('e5db1c1a-95ad-581c-a494-54b3e5960ee0','harian','secondary');
INSERT INTO categories(id,name,kind) VALUES('02e211b6-3151-550f-b502-648616b9f783','kecantikan','secondary');
INSERT INTO categories(id,name,kind) VALUES('7502e5a5-a4fb-5c63-9c98-5bbc78ae22e0','online_shop','secondary');
INSERT INTO categories(id,name,kind) VALUES('4ad2a95d-1a80-5342-9cf7-ba8eb8244be8','bonus','secondary');
INSERT INTO categories(id,name,kind) VALUES('bf4dafa8-8a3b-5816-8dc5-916f7c40a1ab','gaji','secondary');
INSERT INTO categories(id,name,kind) VALUES('1ced2954-0373-5e16-9149-7682a0b9e702','komisi','secondary');
INSERT INTO categories(id,name,kind) VALUES('403e0c1b-40cb-5c2c-b2fb-191eb03c839f','kado','secondary');
INSERT INTO categories(id,name,kind) VALUES('57748df1-2239-5615-a290-4ca943d2d4d0','hadiah','secondary');
INSERT INTO categories(id,name,kind) VALUES('0e07c898-117b-564a-b773-1c106479a7a5','reward','secondary');
INSERT INTO categories(id,name,kind) VALUES('b2400d4d-6aa8-5947-98ea-23f60d8a37aa','sumbangan','secondary');
INSERT INTO categories(id,name,kind) VALUES('394f02a5-bcdb-5285-9e81-4468ee03d07b','undian','secondary');
INSERT INTO categories(id,name,kind) VALUES('40076995-fddf-5a65-a12c-0fc1bafbd0fb','pemberian_masuk','secondary');
INSERT INTO categories(id,name,kind) VALUES('cc267cdb-a623-5741-8a0c-037c281c58da','aktivitas','secondary');
INSERT INTO categories(id,name,kind) VALUES('bb6296ae-bb2f-596c-ae90-94886a017978','game','secondary');
INSERT INTO categories(id,name,kind) VALUES('4c4a3dee-bf20-5bb4-8b34-ccb3e3ab90c3','hiburan','secondary');
INSERT INTO categories(id,name,kind) VALUES('08a1077d-6df4-5fba-a3f0-11e6a7a278db','liburan','secondary');
INSERT INTO categories(id,name,kind) VALUES('6a672c0c-6c7e-5281-b1a8-c687caea90b7','streaming','secondary');
INSERT INTO categories(id,name,kind) VALUES('269f5fee-85bc-51e7-b5b6-00d36ccc296c','tontonan','secondary');
INSERT INTO categories(id,name,kind) VALUES('40c8476b-2e1d-5c89-b68e-0444a48fb62e','apotek','secondary');
INSERT INTO categories(id,name,kind) VALUES('3928e1dd-4db2-53ee-8de1-e6443311871c','kesehatan','secondary');
INSERT INTO categories(id,name,kind) VALUES('631daa6b-22bf-53ed-9b8b-526e1f0e7e85','konsul','secondary');
INSERT INTO categories(id,name,kind) VALUES('fb5e6e15-971e-5e73-8434-a524a6bfafe9','obat','secondary');
INSERT INTO categories(id,name,kind) VALUES('a1559c53-3774-5574-9dbc-749aea0a3da4','prosedur','secondary');
INSERT INTO categories(id,name,kind) VALUES('9fd3f44b-ef79-561f-895c-5b33a7136535','asuransi','secondary');
INSERT INTO categories(id,name,kind) VALUES('07c8b9cb-7b56-51a8-9d30-79fab3b65738','gaji_pihak3','secondary');
INSERT INTO categories(id,name,kind) VALUES('6c80dd89-12cd-54ff-a260-ef06bd370d37','internet_pulsa','secondary');
INSERT INTO categories(id,name,kind) VALUES('ec1920c3-2b5c-56eb-b35d-f6b936e53024','iuran','secondary');
INSERT INTO categories(id,name,kind) VALUES('ecf446e4-0520-5e06-b5fc-a195dab94825','kredit','secondary');
INSERT INTO categories(id,name,kind) VALUES('95100f15-27f9-5d61-a02a-13e74f5655d5','sewa','secondary');
INSERT INTO categories(id,name,kind) VALUES('12851e86-2862-53f5-8e4d-c320c0c4aa91','tagihan','secondary');
INSERT INTO categories(id,name,kind) VALUES('21590b0a-5ae4-5ccd-935e-52893ab26257','utilitas','secondary');
INSERT INTO categories(id,name,kind) VALUES('6a5d9465-4580-5316-9deb-34d6b00f0490','online','secondary');
INSERT INTO categories(id,name,kind) VALUES('a3d94c7e-d0da-5c5d-b85a-863a12e10791','pesawat','secondary');
INSERT INTO categories(id,name,kind) VALUES('205355e2-a72e-59c2-ba25-8bbaf401abdd','pribadi','secondary');
INSERT INTO categories(id,name,kind) VALUES('b33ee0bc-7276-5937-9600-8656cb80129e','transport','secondary');
INSERT INTO categories(id,name,kind) VALUES('463263fc-42b1-5b73-927d-224fb2d52486','umum','secondary');
INSERT INTO categories(id,name,kind) VALUES('64be83d6-9808-5d09-8dac-b2177e77539e','belanja','secondary');

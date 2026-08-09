ALTER TABLE "User" ALTER COLUMN "passwordHash" DROP NOT NULL;

CREATE TABLE "SocialAccount" (
    "id" UUID NOT NULL,
    "provider" TEXT NOT NULL,
    "providerUserId" TEXT NOT NULL,
    "userId" UUID NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SocialAccount_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "SocialAccount_provider_providerUserId_key"
ON "SocialAccount"("provider", "providerUserId");

CREATE UNIQUE INDEX "SocialAccount_userId_provider_key"
ON "SocialAccount"("userId", "provider");

CREATE INDEX "SocialAccount_userId_idx" ON "SocialAccount"("userId");

ALTER TABLE "SocialAccount"
ADD CONSTRAINT "SocialAccount_userId_fkey"
FOREIGN KEY ("userId") REFERENCES "User"("id")
ON DELETE CASCADE ON UPDATE CASCADE;

-- CreateEnum
CREATE TYPE "RecordingStatus" AS ENUM ('PENDING', 'UPLOADING', 'TRANSCRIBING', 'ANALYZING', 'GENERATING_CLIP', 'COMPLETE', 'FAILED');

-- CreateEnum
CREATE TYPE "SubscriptionTier" AS ENUM ('FREE', 'PRO', 'ENTERPRISE');

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "providerUid" TEXT NOT NULL,
    "authProvider" TEXT NOT NULL DEFAULT 'firebase',
    "email" TEXT,
    "emailVerified" BOOLEAN NOT NULL DEFAULT false,
    "displayName" TEXT,
    "profilePicture" TEXT,
    "bio" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Recording" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "audioUrl" TEXT NOT NULL,
    "duration" INTEGER NOT NULL,
    "status" "RecordingStatus" NOT NULL DEFAULT 'PENDING',
    "mood" TEXT,
    "energyLevel" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Recording_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Transcription" (
    "id" TEXT NOT NULL,
    "recordingId" TEXT NOT NULL,
    "text" TEXT NOT NULL,
    "language" TEXT NOT NULL DEFAULT 'en',
    "confidence" DOUBLE PRECISION,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Transcription_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Insight" (
    "id" TEXT NOT NULL,
    "recordingId" TEXT NOT NULL,
    "summary" TEXT NOT NULL,
    "emotionScores" JSONB NOT NULL,
    "keyThemes" JSONB NOT NULL,
    "suggestedActions" JSONB,
    "sentiment" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Insight_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Clip" (
    "id" TEXT NOT NULL,
    "recordingId" TEXT NOT NULL,
    "videoUrl" TEXT NOT NULL,
    "duration" INTEGER NOT NULL,
    "thumbnail" TEXT,
    "sceneStart" INTEGER NOT NULL,
    "sceneEnd" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Clip_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Notification" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "message" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "read" BOOLEAN NOT NULL DEFAULT false,
    "link" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Notification_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_providerUid_key" ON "User"("providerUid");

-- CreateIndex
CREATE INDEX "User_createdAt_idx" ON "User"("createdAt");

-- CreateIndex
CREATE INDEX "Recording_userId_idx" ON "Recording"("userId");

-- CreateIndex
CREATE INDEX "Recording_createdAt_idx" ON "Recording"("createdAt");

-- CreateIndex
CREATE INDEX "Recording_status_idx" ON "Recording"("status");

-- CreateIndex
CREATE UNIQUE INDEX "Transcription_recordingId_key" ON "Transcription"("recordingId");

-- CreateIndex
CREATE INDEX "Transcription_recordingId_idx" ON "Transcription"("recordingId");

-- CreateIndex
CREATE UNIQUE INDEX "Insight_recordingId_key" ON "Insight"("recordingId");

-- CreateIndex
CREATE INDEX "Insight_recordingId_idx" ON "Insight"("recordingId");

-- CreateIndex
CREATE UNIQUE INDEX "Clip_recordingId_key" ON "Clip"("recordingId");

-- CreateIndex
CREATE INDEX "Clip_recordingId_idx" ON "Clip"("recordingId");

-- CreateIndex
CREATE INDEX "Notification_userId_idx" ON "Notification"("userId");

-- CreateIndex
CREATE INDEX "Notification_createdAt_idx" ON "Notification"("createdAt");

-- CreateIndex
CREATE INDEX "Notification_read_idx" ON "Notification"("read");

-- AddForeignKey
ALTER TABLE "Recording" ADD CONSTRAINT "Recording_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Transcription" ADD CONSTRAINT "Transcription_recordingId_fkey" FOREIGN KEY ("recordingId") REFERENCES "Recording"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Insight" ADD CONSTRAINT "Insight_recordingId_fkey" FOREIGN KEY ("recordingId") REFERENCES "Recording"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Clip" ADD CONSTRAINT "Clip_recordingId_fkey" FOREIGN KEY ("recordingId") REFERENCES "Recording"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Notification" ADD CONSTRAINT "Notification_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

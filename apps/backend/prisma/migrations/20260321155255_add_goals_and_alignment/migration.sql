-- CreateEnum
CREATE TYPE "AlignmentLevel" AS ENUM ('CLEAR_PROGRESS', 'PARTIAL_PROGRESS', 'NO_EVIDENCE', 'DEVIATION');

-- AlterTable
ALTER TABLE "Insight" ADD COLUMN     "overallAlignment" DOUBLE PRECISION;

-- CreateTable
CREATE TABLE "Goal" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Goal_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "GoalAlignment" (
    "id" TEXT NOT NULL,
    "insightId" TEXT NOT NULL,
    "goalId" TEXT NOT NULL,
    "score" DOUBLE PRECISION NOT NULL,
    "level" "AlignmentLevel" NOT NULL,
    "reason" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "GoalAlignment_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Goal_userId_idx" ON "Goal"("userId");

-- CreateIndex
CREATE INDEX "GoalAlignment_insightId_idx" ON "GoalAlignment"("insightId");

-- CreateIndex
CREATE UNIQUE INDEX "GoalAlignment_insightId_goalId_key" ON "GoalAlignment"("insightId", "goalId");

-- AddForeignKey
ALTER TABLE "Goal" ADD CONSTRAINT "Goal_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GoalAlignment" ADD CONSTRAINT "GoalAlignment_insightId_fkey" FOREIGN KEY ("insightId") REFERENCES "Insight"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "GoalAlignment" ADD CONSTRAINT "GoalAlignment_goalId_fkey" FOREIGN KEY ("goalId") REFERENCES "Goal"("id") ON DELETE CASCADE ON UPDATE CASCADE;

package main

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
)

type DBQueries struct {
	pool *pgxpool.Pool
}

func ConnectDB(ctx context.Context, databaseURL string) (*pgxpool.Pool, error) {
	pool, err := pgxpool.New(ctx, databaseURL)
	if err != nil {
		return nil, fmt.Errorf("unable to create connection pool: %w", err)
	}

	if err := pool.Ping(ctx); err != nil {
		return nil, fmt.Errorf("unable to ping database: %w", err)
	}

	return pool, nil
}

func NewDBQueries(pool *pgxpool.Pool) *DBQueries {
	return &DBQueries{pool: pool}
}

func (q *DBQueries) GetParticipantIDByUserID(ctx context.Context, userID string) (string, error) {
	var pid string
	err := q.pool.QueryRow(ctx,
		`SELECT participant_id FROM public.profiles WHERE user_id = $1`, userID).Scan(&pid)
	if err != nil {
		return "", fmt.Errorf("profile lookup failed: %w", err)
	}
	return pid, nil
}

func (q *DBQueries) IsUserInGroup(ctx context.Context, groupID, participantID string) (bool, error) {
	var exists bool
	err := q.pool.QueryRow(ctx,
		`SELECT EXISTS(SELECT 1 FROM public.list_members WHERE list_id = $1 AND participant_id = $2)`,
		groupID, participantID,
	).Scan(&exists)
	if err != nil {
		return false, fmt.Errorf("check membership failed: %w", err)
	}
	return exists, nil
}


package main

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type DBQueries struct {
	pool *pgxpool.Pool
}

func ConnectDB(ctx context.Context, databaseURL string) (*pgxpool.Pool, error) {
	config, err := pgxpool.ParseConfig(databaseURL)
	if err != nil {
		return nil, fmt.Errorf("unable to parse database config: %w", err)
	}

	config.ConnConfig.DefaultQueryExecMode = pgx.QueryExecModeSimpleProtocol

	pool, err := pgxpool.NewWithConfig(ctx, config)
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

// CanUseParticipant prevents a caller from inventing participant ids in an
// expense split. A caller may always include themselves, or contacts they
// created or have claimed into their account.
func (q *DBQueries) CanUseParticipant(ctx context.Context, callerID, participantID string) (bool, error) {
	if callerID == participantID {
		return true, nil
	}
	var exists bool
	err := q.pool.QueryRow(ctx, `
		SELECT EXISTS(
			SELECT 1 FROM public.participants p
			LEFT JOIN public.contacts c ON c.participant_id = p.id
			WHERE p.id = $1 AND (c.created_by = $2 OR c.claimed_by_participant_id = $2)
		)`, participantID, callerID).Scan(&exists)
	if err != nil {
		return false, fmt.Errorf("check participant access failed: %w", err)
	}
	return exists, nil
}

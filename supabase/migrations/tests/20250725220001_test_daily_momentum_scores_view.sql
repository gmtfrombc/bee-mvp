-- pgTAP tests for daily_momentum_scores view (not a migration)
SET search_path TO public;

SELECT has_view(
    'public',
    'daily_momentum_scores',
    'daily_momentum_scores view should exist'
);

SELECT columns_are(
    'public',
    'daily_momentum_scores',
    ARRAY['user_id', 'score', 'score_date', 'pillar_breakdown'],
    'daily_momentum_scores view has expected columns'
);

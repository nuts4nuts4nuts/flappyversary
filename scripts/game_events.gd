extends Node

# Game state signals
signal game_started
signal game_restarting  # Emitted BEFORE restart - balls listen to this
signal game_ended
signal game_running_changed(is_running: bool)

# Cluster signals (2048-style merging)
signal cluster_cashing_in(cluster_id: int, value: int, ball_count: int, time: float)
signal cluster_merged(new_value: int, position: Vector2)
signal ball_leaving_screen(ball)  # For danger warning when any ball approaches edge
signal high_score_updated(value: int)

# Legacy target ball signals (kept for background_danger_element compatibility during transition)
signal target_ball_dying(time_remaining: float)
signal target_ball_safe
signal target_ball_cashing_in(wait_time: float)
signal target_ball_cashed_in

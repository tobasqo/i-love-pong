local love = require("love")
local text_utils = require("text_utils")

local NET_SEGMENTS = 51
local MAX_SCORE = 7
local GAME_SPEED = 1

local PADDLE_SPEED = 500
local BALL_SPEED = 600

-- changed by the resize
local screen_width, screen_height
local font_size
local ball_size
local paddle_length, paddle_thiccness

-- changed by the game
local ball_released
local ball_x, ball_y, ball_dx, ball_dy
local paddle_left_x, paddle_left_y, paddle_right_x, paddle_right_y
local paddle_left_dy = 0
local paddle_right_dy = 0
local player_left_score = 0
local player_right_score = 0
local player_turn

local function handle_input(dt)
	-- TODO: add support for joysticks (gamepads)
	-- TODO: don't move if paddle would pinch the ball
	if love.keyboard.isDown("w") then
		local paddle_left_ny = paddle_left_y - dt * PADDLE_SPEED * GAME_SPEED
		paddle_left_y = math.max(math.min(paddle_left_y, paddle_left_ny), 0)
		if not ball_released and player_turn == 1 then
			ball_y = paddle_left_y + paddle_length / 2 - ball_size / 2
		end
		paddle_left_dy = -1
	elseif love.keyboard.isDown("s") then
		local paddle_left_ny = paddle_left_y + dt * PADDLE_SPEED * GAME_SPEED
		paddle_left_y = math.min(math.max(paddle_left_y, paddle_left_ny), screen_height - paddle_length)
		if not ball_released and player_turn == 1 then
			ball_y = paddle_left_y + paddle_length / 2 - ball_size / 2
		end
		paddle_left_dy = 1
	else
		paddle_left_dy = 0
	end

	if love.keyboard.isDown("up") then
		local paddle_right_ny = paddle_right_y - dt * PADDLE_SPEED * GAME_SPEED
		paddle_right_y = math.max(math.min(paddle_right_y, paddle_right_ny), 0)
		if not ball_released and player_turn == 2 then
			ball_y = paddle_right_y + paddle_length / 2 - ball_size / 2
		end
		paddle_right_dy = -1
	elseif love.keyboard.isDown("down") then
		local paddle_right_ny = paddle_right_y + dt * PADDLE_SPEED * GAME_SPEED
		paddle_right_y = math.min(math.max(paddle_right_y, paddle_right_ny), screen_height - paddle_length)
		if not ball_released and player_turn == 2 then
			ball_y = paddle_right_y + paddle_length / 2 - ball_size / 2
		end
		paddle_right_dy = 1
	else
		paddle_right_dy = 0
	end

	if love.keyboard.isDown("space") then
		if not ball_released then
			if player_turn == 1 then
				ball_dx = 1
				ball_dy = paddle_left_dy
			else
				ball_dx = -1
				ball_dy = paddle_right_dy
			end
			ball_released = true
		end
	end
end

local function init_paddles()
	paddle_left_y = screen_height / 2 - paddle_length / 2
	paddle_right_y = screen_height / 2 - paddle_length / 2
end

local function init_ball()
	if player_turn == 1 then
		ball_x = paddle_left_x + paddle_thiccness + ball_size / 4
	else
		ball_x = paddle_right_x - ball_size / 4 * 5
	end
	ball_y = screen_height / 2 - ball_size / 2
	ball_dy = 0
	ball_dx = 0
end

local function check_rectangle_collision(r1x, r1y, r1w, r1h, r2x, r2y, r2w, r2h)
	local l1 = r1x
	local r1 = r1x + r1w
	local t1 = r1y
	local b1 = r1y + r1h
	local l2 = r2x
	local r2 = r2x + r2w
	local t2 = r2y
	local b2 = r2y + r2h
	return not (r1 < l2 or r2 < l1 or b1 < t2 or b2 < t1)
end

local function update_ball(dt)
	if not ball_released then
		return
	end

	local ball_nx = ball_x + dt * ball_dx * BALL_SPEED * GAME_SPEED
	if ball_nx < 0 then
		player_right_score = player_right_score + 1
		player_turn = 1
		ball_released = false
		init_paddles()
		init_ball()
		-- TODO: play point sound
		return
	elseif
		check_rectangle_collision(
			paddle_left_x,
			paddle_left_y,
			paddle_thiccness,
			paddle_length,
			ball_nx,
			ball_y,
			ball_size,
			ball_size
		)
	then
		-- TODO: play paddle bounce sound
		ball_x = paddle_left_x + paddle_thiccness
		ball_dx = -ball_dx
		if paddle_left_dy ~= 0 then
			ball_dy = paddle_left_dy
		end
	elseif
		check_rectangle_collision(
			ball_nx,
			ball_y,
			ball_size,
			ball_size,
			paddle_right_x,
			paddle_right_y,
			paddle_thiccness,
			paddle_length
		)
	then
		-- TODO: play paddle bounce sound
		ball_x = paddle_right_x - ball_size
		ball_dx = -ball_dx
		if paddle_right_dy ~= 0 then
			ball_dy = paddle_right_dy
		end
	elseif ball_nx + ball_size > screen_width then
		player_left_score = player_left_score + 1
		player_turn = 2
		ball_released = false
		init_paddles()
		init_ball()
		-- TODO: play point sound
		return
	else
		ball_x = ball_nx
	end

	local ball_ny = ball_y + dt * ball_dy * BALL_SPEED * GAME_SPEED
	-- TODO: in both cases play wall bounce sound
	if ball_ny < 0 then
		ball_ny = 0
		ball_dy = -ball_dy
	elseif ball_ny + ball_size > screen_height then
		ball_ny = screen_height - ball_size
		ball_dy = -ball_dy
	end
	ball_y = ball_ny
end

local function resize_vars(width, height)
	font_size = height / 80

	paddle_thiccness = width / 70
	paddle_length = height / 8
	paddle_left_x = paddle_thiccness
	paddle_right_x = width - 2 * paddle_thiccness

	ball_size = height / 40

	-- FIXME: this is off
	if paddle_left_y ~= nil then
		local width_ratio = screen_width / width
		local height_ratio = screen_height / height
		local width_diff = screen_width - width
		local height_diff = screen_height - height

		paddle_left_y = paddle_left_y - height_diff * height_ratio
		paddle_right_y = paddle_right_y - height_diff * height_ratio

		ball_x = ball_x - width_diff * width_ratio
		ball_y = ball_y - height_diff * height_ratio
	end

	screen_width = width
	screen_height = height
end

local function is_game_over()
	return player_left_score == MAX_SCORE or player_right_score == MAX_SCORE
end

local function draw_game_over()
	local game_over_text = "Game Over"
	local game_over_text_width = text_utils.text_width(game_over_text, font_size)
	text_utils.render_text(
		game_over_text,
		screen_width / 2 - game_over_text_width / 2,
		screen_height / 2 - text_utils.text_height(game_over_text, font_size) - font_size,
		font_size
	)
	local player_won
	if player_left_score == MAX_SCORE then
		player_won = 1
	else
		player_won = 2
	end

	local player_won_text = string.format("Player %d wins", player_won)
	local player_won_text_font_size = font_size * 0.75
	text_utils.render_text(
		player_won_text,
		screen_width / 2 - text_utils.text_width(player_won_text, player_won_text_font_size) / 2,
		screen_height / 2 + font_size,
		player_won_text_font_size
	)
end

local function draw_net()
	local net_length = screen_height / NET_SEGMENTS

	love.graphics.setLineWidth(3)
	for i = 1, NET_SEGMENTS do
		if i % 2 == 1 then
			love.graphics.line(screen_width / 2, (i - 1) * net_length, screen_width / 2, i * net_length)
		end
	end
end

local function draw_scores()
	local y = 2 * font_size

	local player_left_score_str = tostring(player_left_score)
	text_utils.render_text(
		player_left_score_str,
		screen_width / 2 - text_utils.text_width(player_left_score_str, font_size) - 2 * font_size,
		y,
		font_size
	)

	local player_right_score_str = tostring(player_right_score)
	text_utils.render_text(player_right_score_str, screen_width / 2 + 2 * font_size, y, font_size)
end

local function draw_paddles()
	love.graphics.rectangle("fill", paddle_left_x, paddle_left_y, paddle_thiccness, paddle_length)
	love.graphics.rectangle("fill", paddle_right_x, paddle_right_y, paddle_thiccness, paddle_length)
end

local function draw_ball()
	love.graphics.rectangle("fill", ball_x, ball_y, ball_size, ball_size)
end

function love.load()
	screen_width = 1600
	screen_height = 900

	love.window.setMode(screen_width, screen_height, { resizable = true })
	love.window.setTitle("Pong")

	love.graphics.setBackgroundColor(0x25 / 0xFF, 0x27 / 0xFF, 0x20 / 0xFF, 1)
	love.graphics.setColor(1, 1, 1, 1)

	math.randomseed(os.time())
	player_turn = math.random(1, 2)

	resize_vars(screen_width, screen_height)
	init_paddles()
	init_ball()
end

function love.update(dt)
	if is_game_over() then
		return
	end

	handle_input(dt)
	update_ball(dt)
end

function love.draw()
	draw_net()
	draw_scores()
	draw_paddles()
	draw_ball()

	if is_game_over() then
		draw_game_over()
		-- TODO: play game won sound (once)
	end
end

function love.resize(width, height)
	resize_vars(width, height)
end

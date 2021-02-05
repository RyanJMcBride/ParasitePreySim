close all; clc; clear all;
%% SET MAKE VIDEO
MAKE_VIDEO = true;
ANIMATE_MODEL = true;

%% Set field conditions
WIDTH = 200;
HEIGHT = 200;

%% Set simulation conditions
NUM_STEPS = 500;

% Parasite conditions
PARASITE_RATIO = 0.1;
PARASITE_AGE_LIMIT = 20; % f1

% Food conditions
FOOD_RATIO = 0.1;
CHANCE_OF_FOOD_DEATH = 0.1; % f2
NUM_FOOD_TO_SPAWN = 0; % Spawn f3 number of food in a random empty cell
CHANCE_TO_SPAWN_NEIGHBORING_FOOD = 0.4; % f4 ratio to spawn food on neighboring food cell

food_history = false(HEIGHT, WIDTH, NUM_STEPS+1);
parasites_history = false(HEIGHT, WIDTH, NUM_STEPS+1);

%% Populate field with parasites and food
% Create initial positions of parasites
r = rand(HEIGHT, WIDTH);
P = r <= PARASITE_RATIO;

% Create initial positions of food
free_space = find(~P);
r = rand(size(free_space));
food_spawn = r <= (FOOD_RATIO/(1 - PARASITE_RATIO));
food_index = free_space(food_spawn);
F = false(size(P));
F(food_index) = 1;

%% Initialise parasites and food objects
parasites = Parasites(P);
food = Food(F);

food_history = false(HEIGHT, WIDTH, NUM_STEPS+1);
parasites_history = false(HEIGHT, WIDTH, NUM_STEPS+1);

food_history(:, :, 1) = food.getPositions();
parasites_history(:, :, 1) = parasites.getPositions();

%% Pre-generate actions for cells - assuming 4 directions
NUM_DIRECTIONS = 4; % 4 directions -> north, south, east, west
pdf = ones(NUM_DIRECTIONS, 1) / NUM_DIRECTIONS;
cdf = cumsum(pdf);

cell_actions = rand(HEIGHT, WIDTH, NUM_STEPS);

%% Initialise ParasiteSimulation with for given parameters
simulation = ParasiteSimulation( ...
    parasites, ...
    food, ...
    PARASITE_AGE_LIMIT, ...
    CHANCE_OF_FOOD_DEATH, ...
    NUM_FOOD_TO_SPAWN, ...
    CHANCE_TO_SPAWN_NEIGHBORING_FOOD ...
);

%% Initialize population vectors for food and parasites
num_pred = sum(P(:));
num_food = sum(F(:));
TOTAL = num_pred + num_food;
population_parasites = zeros(NUM_STEPS+1,1);
population_food = zeros(NUM_STEPS+1,1);

population_parasites(1) = num_pred;
population_food(1) = num_food;
t = zeros(NUM_STEPS+1,1);

%% Intialize video settings
% Video settings
% delay_per_frame = 0.25;
% fps = 1/delay_per_frame; %frames per second

if (MAKE_VIDEO && ANIMATE_MODEL)
    fps = 30;
    % Initialize video object
    oParasiteVideo = VideoWriter(['PrasiteSimulation', num2str(fps), 'fps']); 
    oParasiteVideo.FrameRate = fps; 
    open(oParasiteVideo);
end

%% Display Initial values
if(ANIMATE_MODEL)
    h = figure;
    set(h, 'Position', get(0, 'Screensize'))
    parasite_positions = parasites.getPositions();
    food_positions = food.getPositions();

    % Show Top Down view
    subplot(2, 2, [1, 3]);
    simulation.DisplayField(parasites, food);    
    title('Top-down view');
    xlabel(['# Parasites: ', num2str(sum(parasite_positions(:))), ...
        ' # Food: ', num2str(sum(food_positions(:))), ...
        ' # Steps: ', num2str(0)]);

    % Show Phase Plot
    subplot(2, 2, 2);
    hold on;
    plot(population_food(1),population_parasites(1),'.r');
    title('Parasite Phase Plot');
    ylabel('# of Parasites');
    xlabel('# of food');
    axis([0, WIDTH * HEIGHT, 0, WIDTH * HEIGHT]);
    hold off;
    axis square;

    % Show Population timeline
    subplot(2, 2, 4);
    plot(t,population_food, '.b')
    hold on
    plot(t,population_parasites, '.r')
    title('Parasite/food vs time')
    ylabel('# of Parasites/food')
    xlabel('Time')
    legend('Number of food','Number of parasites','Location','NorthWest','Orientation','vertical')
    axis([0, length(t), 0, WIDTH * HEIGHT]);
    drawnow; 

    if (MAKE_VIDEO)
        writeVideo(oParasiteVideo, getframe(h));
    end
end
%% Begin simulation
for i = 1:NUM_STEPS     
    simulation.next(cell_actions(:, :, i), cdf);    
    
    parasite_positions = parasites.getPositions();
    food_positions = food.getPositions();
    
    food_history(:, :, i+1) = food_positions;
    parasites_history(:, :, i+1) = parasite_positions;
    
    population_parasites(i+1) = sum(parasite_positions(:));
    population_food(i+1) = sum(food_positions(:));
    t(i+1) = i;   
    
    %% Make Video
    if(MAKE_VIDEO || ANIMATE_MODEL)
        figure(h);
        % Show top-down view
        subplot(2, 2, [1, 3]);
        simulation.DisplayField(parasites, food);    
        title('Top-down view');
        xlabel(['# Parasites: ', num2str(population_parasites(i+1)), ...
            ' # Food: ', num2str(population_food(i+1)), ...
            ' # Steps: ', num2str(i)]);

        % Show phase plot
        subplot(2, 2, 2);
        hold on;
        plot(population_food(i),population_parasites(i),'.r');
        title('Parasite Phase Plot');
        ylabel('# of Parasites');
        xlabel('# of food');
        axis([0, WIDTH * HEIGHT, 0, WIDTH * HEIGHT]);
        hold off;
        axis square;

        % Show population timeline
        subplot(2, 2, 4);
        plot(t,population_food, '.b')
        hold on
        plot(t,population_parasites, '.r')
        title('Parasite/food vs time')
        ylabel('# of Parasites/food')
        xlabel('Time')
        legend('Number of food','Number of parasites','Location','NorthWest','Orientation','vertical')
        axis([0, length(t), 0, WIDTH * HEIGHT]);
        drawnow; 

        % Write frame to video
        if (MAKE_VIDEO)
            writeVideo(oParasiteVideo, getframe(h));
        end
        %% END OF SIMULATION LOOP
    end
end

%% Finish off video
if (MAKE_VIDEO && ANIMATE_MODEL)
    writeVideo(oParasiteVideo, getframe(h)); % write the frame one last time
    close(oParasiteVideo);
end

%% Plot only phase plot and population over time
figure;
subplot(1,2,1)
hold on;
for i = 1:length(population_food)    
   plot(population_food(i),population_parasites(i),'.r');
end
title('Parasite Phase Plot')
ylabel('# of Parasites')
xlabel('# of food')
hold off

subplot(1,2,2)
plot(t,population_food, '.b')
hold on
plot(t,population_parasites, '.r')
title('Parasite/food vs time')
ylabel('# of Parasites/food')
xlabel('Time')
legend('Number of food','Number of parasites','Location','NorthWest','Orientation','vertical')

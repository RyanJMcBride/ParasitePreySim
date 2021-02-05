classdef ParasiteSimulation < handle
    %PARASITESIMULATION Sets the conditions for the parasite simulation
    properties (Access = private)
        parasites;
        food;
        f1;
        f2;
        f3;
        f4;
    end
    
    methods
        function this = ParasiteSimulation(parasites, food, f1, f2, f3, f4)
        %PARASITESIMULATION Constructor
            this.parasites = parasites;
            this.food = food;
            this.f1 = f1;
            this.f2 = f2;
            this.f3 = f3;
            this.f4 = f4;
        end
        
        function this = next(this, action_map, nswe_cdf)
        %NEXT Perform a set of instructions on the parasites and food based
        %   on the given action_map and direction probabilities. This
        %   method includes moving the parasite, checking for food it
        %   consumed, birthing the parasites relative to the food consumed
        %   and its parents original position, kill old parasites, kill 
        %   random food, spawn food randomly on spare cells, and spawn food
        %   next to an existing food agent where possible.
            moved_parasites = this.parasites.moveParasites(action_map, nswe_cdf);
            consumed_food = this.consumedFood(this.food, moved_parasites);
            this.birthParasites(this.parasites, consumed_food);
            this.killOldParasites(this.parasites, this.f1);
            
            this.killRandomFood(this.food, this.f2);
            this.spawnRandomFood(this.parasites, this.food, this.f3);
            this.spawnNeighboringFood(this.parasites, this.food, this.f4);
        end
    end
    
    methods (Static, Access = private)   
        function [ consumed_food ] = consumedFood(food, moved_parasites)
        %CONSUMEDFOOD Returns the relative points of food consumed and the
        %   directions of the parasites' that consumed the food. Food is also
        %   updated accordingly.
            food_positions = food.getPositions();
            consumed_food = {
                moved_parasites{1} & food_positions, ...
                moved_parasites{2} & food_positions, ...
                moved_parasites{3} & food_positions, ...
                moved_parasites{4} & food_positions};
            
            food.removeFood( consumed_food{1} ...
                | consumed_food{2} ...
                | consumed_food{3} ...
                | consumed_food{4} ...
            );
        end
        
        function birthParasites(parasites, consumed_food)
            %BIRTHPARASITES set new parasites where origin of parents that
            %   consumed the food were.
            
            % Calculating the origin of the parents that consumed the foods
            baby_parasites = WrapAround.shiftDown(consumed_food{Compass.north}) ... % north parent
                | WrapAround.shiftUp(consumed_food{Compass.south}) ... % south parent
                | WrapAround.shiftLeft(consumed_food{Compass.east}) ... % east parent
                | WrapAround.shiftRight(consumed_food{Compass.west}); % west parent
            
            parasites.addNewParasites(baby_parasites);
        end
        
        function killOldParasites(parasites, age_limit)
        %KILLOLDPARASITES Kill parasites that exceeded the age limits
            dead_parasites = parasites.getAge() >= age_limit;
            parasites.removeParasites(dead_parasites);
        end
        
        function spawnRandomFood(parasites, food, f3)
        %SPAWNRANDOMFOOD Spawn f3 number of food randomly on empty cells.
        %   Does not spawn food on empty cells when number of empty cells
        %   is less than f3.
            spare_cells = ~(parasites.getPositions() | food.getPositions());
            spare_cells_index = find(spare_cells);

            if length(spare_cells_index(:)) >= f3
                r = randperm(length(spare_cells_index(:)), f3);
                food.addFood(spare_cells_index(r));
            end
        end
        
        function spawnNeighboringFood(parasites, food, f4)
        %SPAWNNEIGHBORINGFOOD Spawn neighboring food for every food agent
        %   on map when possible. Has u < f4 chance of occuring.
            parasite_positions = parasites.getPositions();
            food_positions = food.getPositions();
            valid_cells = ~(parasite_positions | food_positions);
            
            % Get list of points of food spawning event can occur and
            % shuffle list.
            food_list = find(ParasiteSimulation.getFoodsThatCanSpawn(parasites, food));
            len_food_list = length(food_list(:));
            shuffle_food_list_index = randperm(len_food_list);            
            food_list = food_list(shuffle_food_list_index);
            
            for i = 1:len_food_list            
                u = rand;
                if (u < f4)
                    % Gets the neighboring cells of a food agent and
                    % shuffles it.
                    neighbor_list = ParasiteSimulation.getNeighboringCells(food, food_list(i));
                    n_length = length(neighbor_list); 
                    shuffle_neighbor_index = randperm(length(neighbor_list(:)));
                    neighbor_list = neighbor_list(shuffle_neighbor_index);
                    
                    % Spawn neighboring food for the given agent in random
                    % neighboring order
                    for j = 1:n_length
                        if valid_cells(neighbor_list(j))
                            food.addFood(neighbor_list(j));
                            break;
                        end
                    end
                end
            end
        end
        
        function killRandomFood(food, f2)
        %KILLRANDOMFOOD Kills the food for the given probability f2
            food_index = find(food.getPositions());
            u = rand(size(food_index));
            food.removeFood(food_index(u < f2));
        end
    end
    
    methods (Static, Access = public)
        function [foods_that_can_spawn] = getFoodsThatCanSpawn(parasites, food)
        %GETFOODSTHATCANSPAWN Returns the food agents where it's possible
        %   for a neighboring food to spawn. Directions include North, South, East, West,
        %   North-East, North-West, South-East, and South-West.
        
            % Shift food in all directions
            food_positions = food.getPositions();
            empty_cells = ~(parasites.getPositions() | food.getPositions());
            n = WrapAround.shiftUp(food_positions);
            s = WrapAround.shiftDown(food_positions);
            e = WrapAround.shiftRight(food_positions);
            w = WrapAround.shiftLeft(food_positions);
            ne = WrapAround.shiftUp(e);
            nw = WrapAround.shiftUp(w);
            se = WrapAround.shiftDown(e);
            sw = WrapAround.shiftDown(w);  
            
            % Get food points that shifted without interference
            next_n = WrapAround.shiftDown(n & empty_cells);
            next_s = WrapAround.shiftUp(s & empty_cells);
            next_e = WrapAround.shiftLeft(e & empty_cells);
            next_w = WrapAround.shiftRight(w & empty_cells);            
            next_ne = WrapAround.shiftDown(WrapAround.shiftLeft(ne & empty_cells));
            next_nw = WrapAround.shiftDown(WrapAround.shiftRight(nw & empty_cells));
            next_se = WrapAround.shiftUp(WrapAround.shiftLeft(se & empty_cells));
            next_sw = WrapAround.shiftUp(WrapAround.shiftRight(sw & empty_cells));  
            
            % Assign the returing value
            foods_that_can_spawn = ( next_n ...
                | next_s ...
                | next_e ...
                | next_w ...
                | next_ne ...
                | next_nw ...
                | next_se ...
                | next_sw ...
            );
        end
        
        function [neighboring_cells] = getNeighboringCells(food, index)
        %GETNEIGHBORINGCELLS Gets a list of neighboring cell for a given
        %   point on the map. Directions include North, South, East, West,
        %   North-East, North-West, South-East, and South-West.
            [rows, cols] = size(food.getPositions());
            [row, col] = ind2sub([rows, cols], index);
            
            % Get index values - wrap around if flow over map limit
            top_index = row - 1;
            if (top_index <= 0)
                top_index = rows;
            end

            bottom_index = row + 1;
            if (bottom_index > rows)
                bottom_index = 1;
            end

            left_index = col - 1;
            if (left_index <= 0)
                left_index = cols;
            end

            right_index = col + 1;
            if (right_index > cols)
                right_index = 1;
            end            
            
            % Calculates the indexes for all the directions
            n_index = sub2ind([rows, cols], top_index, col);
            s_index = sub2ind([rows, cols], bottom_index, col);
            e_index = sub2ind([rows, cols], row, right_index);
            w_index = sub2ind([rows, cols], row, left_index);
            ne_index = sub2ind([rows, cols], top_index, right_index);
            nw_index = sub2ind([rows, cols], top_index, left_index);
            se_index = sub2ind([rows, cols], bottom_index, right_index);
            sw_index = sub2ind([rows, cols], bottom_index, left_index);
            
            % Assign the indexes for returning value
            neighboring_cells = [ ...
                n_index; ...
                s_index; ...
                e_index; ...
                w_index; ...
                ne_index; ...
                nw_index; ...
                se_index; ...
                sw_index; ...
            ];
        end
        
        function DisplayField( parasites, food )
        %DISPLAYFIELD Displays the points of the parasites and food,
        %   assuming there is no overlapping of the two.
            spy(parasites.getPositions(), 'r');
            hold on;
            spy(food.getPositions(), 'b');
            hold off;
        end
    end
end

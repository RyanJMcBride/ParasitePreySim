classdef Parasites < handle
    %PARASITE Summary of this class goes here
    %   Detailed explanation goes here  
    properties (Access = private)        
        positions;
        age;
    end

    methods (Access = public)
        function this = Parasites(initial_positions_map)
        %INITIALISE PARASITES POSITION AND THEIR RELATIVE AGES
            this.positions = initial_positions_map;
            
            this.age = double(initial_positions_map);
            this.age(~initial_positions_map) = NaN;
            this.age(initial_positions_map) = 0;
        end
        
        function positions = getPositions(this)
        %GETPOSITIONS Get the current positions of the parasites
            positions = this.positions;
        end
        
        function age = getAge(this)
        %GETAGE Get the age map of the parasites
            age = this.age;
        end

        function [ moved_parasites, origin_parasites ] = moveParasites(this, action_map, nsew_cdf )
            %MOVEPARASITES Move parasites according to action_map and
            %   probalility proportions set by nsew_cdf
            
            moved_parasites = this.nextMovedPoints( ...
                action_map, ...
                nsew_cdf);
            
            origin_parasites = this.originOfMovedParasites(moved_parasites);
            
            this.updateAgeFromMove(moved_parasites, origin_parasites);
            
            % Set points where parasites moved away from, to 0
            this.positions(origin_parasites{1} ...
                | origin_parasites{2} ...
                | origin_parasites{3} ...
                | origin_parasites{4}) = 0;

            % Points where parasites moved to, are set to 1
            this.positions(moved_parasites{1} ...
                | moved_parasites{2} ...
                | moved_parasites{3} ...
                | moved_parasites{4}) = 1;
        end
        
        function addNewParasites(this, positions)
        %ADDNEWPARASITES Sets the new points of parasites to 1 and the
        %   relative ages to 0.
            this.age(positions) = 0;
            this.positions(positions) = 1;
        end
        
        function removeParasites(this, positions)
        %REMOVEPARASITES Sets the new points of parasites to 0 and the
        %   relative ages to NaN - basically wiping the parasites existence.
            this.age(positions) = NaN; 
            this.positions(positions) = 0;
        end
    end    
    
    methods (Access = private)        
        function updateAgeFromMove(this, moved, origin )
        %UPDATEPARASITEAGE update the parasites' ages and shift the age map
        %accordingly to the moving parasites.
            this.age = this.age + 1;
            this.age(moved{Compass.north}) = this.age(origin{Compass.north});
            this.age(moved{Compass.south}) = this.age(origin{Compass.south});
            this.age(moved{Compass.east}) = this.age(origin{Compass.east});
            this.age(moved{Compass.west}) = this.age(origin{Compass.west});

            % Remove age points where parasites are no longer there
            this.age(origin{Compass.north} ...
                | origin{Compass.south} ...
                | origin{Compass.east} ...
                | origin{Compass.west}) = NaN;
        end
        
        function [ moved_parasite_positions ] = nextMovedPoints(this, action_map, nsew_cdf )
        %NEXTMOVEDPOINTS Gets the next set of points for parasites
        %based on a map of actions and direction probabilities.
            north = (action_map <= nsew_cdf(1)) & this.positions;

            south = ((action_map > nsew_cdf(1)) ...
                & (action_map <= nsew_cdf(2))) & this.positions;

            east = ((action_map > nsew_cdf(2)) ...
                & (action_map <= nsew_cdf(3))) & this.positions;

            west = ((action_map > nsew_cdf(3)) ...
                & (action_map <= nsew_cdf(4))) & this.positions;

            % Wrap around condition for attempted parasite movement
            p_n = WrapAround.shiftUp(north);
            p_s = WrapAround.shiftDown(south);
            p_e = WrapAround.shiftRight(east);
            p_w = WrapAround.shiftLeft(west);

            % Get next parasite positions that don't collide into each other
            next_pn = p_n & ~(p_e | p_w | p_s) & ~this.positions;
            next_ps = p_s & ~(p_n | p_w | p_e) & ~this.positions;
            next_pe = p_e & ~(p_n | p_w | p_s) & ~this.positions;
            next_pw = p_w & ~(p_n | p_e | p_s) & ~this.positions;

            % Return parasites that successfully moved without collision
            moved_parasite_positions = {next_pn, next_ps, next_pe, next_pw};
        end
    end
    
    methods (Static, Access = private)     
        function [ origin ] = originOfMovedParasites( moved_parasites )
        %ORIGINMOVEDPARASITES Gets the origin of the moved parasites
            shifted_pn = WrapAround.shiftDown(moved_parasites{Compass.north});
            shifted_ps = WrapAround.shiftUp(moved_parasites{Compass.south});
            shifted_pe = WrapAround.shiftLeft(moved_parasites{Compass.east});
            shifted_pw = WrapAround.shiftRight(moved_parasites{Compass.west});
            
            origin = {shifted_pn, shifted_ps, shifted_pe, shifted_pw};
        end
    end
end


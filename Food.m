classdef Food < handle
    %FOOD class for inserting, removing, and getting food information
    
    properties (Access = private)
        positions;
    end
    
    methods (Access = public)
        function this = Food(initial_position_map)
            this.positions = initial_position_map;
        end
        
        function positions = getPositions(this)
            positions = this.positions;
        end
        
        function removeFood(this, remove_mask)
            this.positions(remove_mask) = 0;
        end
        
        function addFood(this, add_mask)
            this.positions(add_mask) = 1;
        end
        
        function [result] = getFoodInIndex(this, index)
            result = this.position(index);
        end
    end
end


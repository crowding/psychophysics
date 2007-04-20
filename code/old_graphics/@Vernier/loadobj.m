function this = loadobj(this)
% Translate older Vernier trials.

%There was a problem with phase offsets being shown incorrectly for
%CauchyBars. Thus the value of ddp has to be translated to reflect what was
%actually displayed. Note the use of recorded SVN revision information to
%bring this about.

this = cell_2_mat(cellmap(@translate, this));

function this = translate(this)
    if isa(this.primitive, 'CauchyBar')
        1;
        if this.ddp ~= 0 && revision(this.svn, 'texture_movie.m') < 52
			this = [];
			return;
            %Verniers with phase offset before this revision were bad.
            %The phase value was multiplied by the temporal frequency
            %omega.
            %We need to undo this to analyze the trial properly.
            c = this.primitive;
            
            sigma = c.order*c.size(1)/2/pi;
            omega = -c.velocity * c.order / sigma;
        
            this.ddp = mod(this.ddp * omega, 2*pi);
            if (this.ddp > pi)
               this.ddp = this.ddp - 2*pi;
            end
        end
    end

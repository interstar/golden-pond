package;
import haxe.ds.StringMap;
import haxe.ds.IntMap;
import Mode;


class ChordThing {
    public var key:Int;
    public var mode:Mode;
    public var degree:Int;
    public var length:Int;
    public var modifiers:Array<Modifier>;
    public var inversion:Int;
    public var secondary_degree:Null<Int>;

    public function new(key:Int, mode:Mode, degree:Int, length:Int = 1) {
        this.key = key;
        this.mode = mode;
        this.degree = degree;
        this.length = length;
        this.modifiers = [];
        this.inversion = 0;
        this.secondary_degree = null;
    }



    public function equals(other:ChordThing):Bool {
        //trace("In ChordThing::equals");
    	//trace(this);
    	//trace(other);
        if (this.key != other.key || this.mode != other.mode || this.degree != other.degree || this.length != other.length || this.inversion != other.inversion) {
            //trace("Mismatch found:");
            //trace("this.key: " + this.key + ", other.key: " + other.key);
            //trace("this.mode: " + this.mode + ", other.mode: " + other.mode);
            //trace("this.degree: " + this.degree + ", other.degree: " + other.degree);
            return false;
        }

        if (this.modifiers.length != other.modifiers.length) {
            //trace("Modifier length mismatch:");
            //trace("this.modifiers.length: " + this.modifiers.length + ", other.modifiers.length: " + other.modifiers.length);
            return false;
        }

        for (i in 0...this.modifiers.length) {
            if (this.modifiers[i] != other.modifiers[i]) {
                //trace("Modifier mismatch at index " + i + ":");
                //trace("this.modifiers[i]: " + this.modifiers[i] + ", other.modifiers[i]: " + other.modifiers[i]);
                return false;
            }
        }

        return true;
    }

    public function set_as_secondary(secondary_degree:Int):ChordThing {
        this.modifiers.push(Modifier.SECONDARY);
        this.secondary_degree = secondary_degree;
        return this;
    }

    public function swap_mode():ChordThing {
        if (this.mode == MAJOR) {
            this.mode = MINOR;
        } else {
            this.mode = MAJOR;
        }
        return this;
    }

    public function modal_interchange():ChordThing {
        this.modifiers.push(Modifier.MODAL_INTERCHANGE);
        return this;
    }

    public function has_modal_interchange():Bool {
        return this.modifiers.indexOf(Modifier.MODAL_INTERCHANGE) != -1;
    }

    public function seventh():ChordThing {
        if (this.modifiers.indexOf(Modifier.NINTH) != -1) {
            this.modifiers.splice(this.modifiers.indexOf(Modifier.NINTH), 1);
        }
        this.modifiers.push(Modifier.SEVENTH);
        return this;
    }

    public function ninth():ChordThing {
        if (this.modifiers.indexOf(Modifier.SEVENTH) != -1) {
            this.modifiers.splice(this.modifiers.indexOf(Modifier.SEVENTH), 1);
        }
        this.modifiers.push(Modifier.NINTH);
        return this;
    }

    public function set_inversion(inversion:Int):ChordThing {
        this.inversion = inversion;
        return this;
    }

    public function set_voice_leading():ChordThing {
        this.modifiers.push(Modifier.VOICE_LEADING);
        return this;
    }

    public function toString():String {
        var modeStr = (this.mode == MAJOR) ? "MAJOR" : "MINOR";
        var degree_repr = if (this.modifiers.indexOf(Modifier.SECONDARY) != -1)
            "(" + this.secondary_degree + "/" + this.degree + ")"
        else
            "" + this.degree;

        return "ChordThing(" + this.key + "," + modeStr + "," + degree_repr + "," + this.inversion + "," + this.length + ") + " + this.modifiers.toString();
    }

    public function clone():ChordThing {
        var ct = new ChordThing(this.key, this.mode, this.degree, this.length);
        ct.modifiers = this.modifiers.copy();
        ct.inversion = this.inversion;
        ct.secondary_degree = this.secondary_degree;
        return ct;
    }

    public function has_extensions():Bool {
        return this.modifiers.indexOf(Modifier.SEVENTH) != -1 || this.modifiers.indexOf(Modifier.NINTH) != -1;
    }

    public function get_mode():Mode {
        if (this.has_modal_interchange()) {
            return (this.mode == MINOR) ? MAJOR : MINOR;
        } else {
            return this.mode;
        }
    }
 
}


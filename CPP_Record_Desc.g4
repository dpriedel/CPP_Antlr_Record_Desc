/*

    multiple Python statements in actions need to be on separate lines
    otherwise, they run together in the generated code and cause
    Python syntax errors which show up when the module is executed.
    
*/

 
grammar PY_Record_Desc ;

options {
    language=Cpp;
}

tokens {
    COMMA = ',' ;
    TAB =   '\t';
    SPACE = ' ';
    COLON = ':';
    DASH = '-';
}

@header {
import PY_Record_Field 
}

/*------------------------------------------------------------------
 * PARSER RULES
 *------------------------------------------------------------------*/

record_desc returns[aRecordDesc]
scope {
    theRecord;
    recordType;
    useFieldNames;
    lengthDataType;
    needStart;
    needEnd;
    needLength;
    tagged_field_count;
}
@init {
    $record_desc::theRecord = None;
    $record_desc::recordType = None;
    $record_desc::useFieldNames = None;
    $record_desc::lengthDataType = None;
    $record_desc::needStart = False;
    $record_desc::needEnd = False;
    $record_desc::needLength = False;
    $record_desc::tagged_field_count = 0;
}
@after {
    $aRecordDesc = $record_desc::theRecord;
}
            :   (fixed_record
                | variable_record
                | fixed_tagged_record
                | union_record)
                EOF
                ;

fixed_record :  FIXED_RECORD
                NEWLINE {
                    $record_desc::theRecord = PY_Record_Field.CFixedRecord();
                    $record_desc::recordType = "Fixed" ;
                }
                field_names_used
                NEWLINE
                fixed_header
                field_list
                ;

variable_record :   VARIABLE_RECORD
                    NEWLINE {
                        $record_desc::theRecord = PY_Record_Field.CFixedRecord();
                        $record_desc::recordType = "Variable" ;
                    }
                    variable_header
                    ;
                    
fixed_tagged_record :   FIXED_TAGGED_RECORD
                        NEWLINE {
                            $record_desc::theRecord = PY_Record_Field.CFixedTaggedRecord();
                            $record_desc::recordType = "Fixed";     #  just for processing the fixed fields part
                        }
                        field_names_used
                        NEWLINE
                        fixed_header
                        field_list
                        TAGGED_HEADER {$record_desc::recordType = "Tagged"; }
                        YES
                        NEWLINE
                        INT {
                            $record_desc::theRecord.SetTagFieldCount(int($INT.getText()));
                            $record_desc::theRecord.SetEndOfFixed();
                        } 
                        NEWLINE
                        tag_list
                        ;

union_record :  UNION_RECORD
                NEWLINE {
                    $record_desc::theRecord = PY_Record_Field.CUnionRecord();
                    $record_desc::recordType = "Union";
                }
                union_header
                ;


fixed_header :  a=length_data_type {
                    $record_desc::lengthDataType = $a.text;
                    $record_desc::theRecord.SetStartEndLenType($a.text);
                }
                COMMA
                field_table_delim
                NEWLINE
                buffer_length {$record_desc::theRecord.SetBufferLength($buffer_length.text); }
                NEWLINE
                ;

variable_header :   variable_record_delim ;


union_header :  variable_record_delim ;

field_names_used :  YES { $record_desc::useFieldNames = True ;}
                    | NO { $record_desc::useFieldNames = False ;}
                    ;

length_data_type :  STARTEND {
                        $record_desc::needStart = True;
                        $record_desc::needEnd = True;
                    } 
                    | STARTLEN {
                        $record_desc::needStart = True;
                        $record_desc::needLength = True;
                    }
                    | LENONLY {$record_desc::needStart = True; }
                    ;

buffer_length : INT ;

field_list :    field_entry[($record_desc::needLength or $record_desc::needEnd)]
                (
                    (field_type
                    | field_start_reset)
                    | NEWLINE
                )*
                ;

field_type :    (combo_field) => combo_field
                | (synth_field) => synth_field
                | (skip2delim_field) => skip2delim_field
                | field_entry[($record_desc::needLength or $record_desc::needEnd)]
                ;
                
tag_list :  NEWLINE* tag_field
                ((combo_field) => combo_field
                | (synth_field) => synth_field
                | (skip2delim_field) => skip2delim_field
                | tag_field
                | NEWLINE)*
                ;

field_start_reset : ORG_HEADER (a=FIELD_NAME | b=INT) NEWLINE {
                        $record_desc::theRecord.ResetNextFieldOffset(field_name=(a.getText() if a else None), field_number=(b.getText() if b else None));
                    } ;

tag_field
@init {
    a = None;
    f = None;
}
            :   ((field_modifier) => field_modifier) ? {
                    a=$field_modifier.f_modifier;
                    f=$field_modifier.repeat_count;
                }
                b=FIELD_NAME
                NEWLINE {
                    new_field = eval("PY_Record_Field.C\%s\%sField(repeat_count=f, field_name=$b.text)" \
                        \% ((a if a else ""), $record_desc::recordType));
                    $record_desc::theRecord.AddTagField(new_field);
                }
                ;
            
combo_field
scope {
    line_number
}
@after {
    print "Skipping Combo Field at line \%i" \% $combo_field::line_number ;
}
            :   COMBO {$combo_field::line_number = $COMBO.getLine(); }
                field_def_delim_char
                FIELD_NAME
                field_def_delim_char
                (NAME | NUMBER)
                field_def_delim_char
                (field_separator_char)?
                field_def_delim_char
                field_name_list
                NEWLINE
                ;
                
synth_field
scope {
    line_number
}
@after {
    print "Skipping SYNTH Field at line \%i" \% $synth_field::line_number ;
}
            :   SYNTH {$synth_field::line_number = $SYNTH.getLine(); }
                field_def_delim_char
                FIELD_NAME
                field_def_delim_char
                (NAME | NUMBER)
                field_def_delim_char
                field_separator_char
                field_def_delim_char
                field_name_list
                NEWLINE
                ;

skip2delim_field
               :   SKIP2DELIM 
                   field_def_delim_char
                   a=FIELD_NAME
                   field_def_delim_char
                   (NAME | NUMBER)
                   field_def_delim_char
                   c=field_separator_char
                   field_def_delim_char
                   b=FIELD_NAME
	               NEWLINE {
	                    new_field = eval("PY_Record_Field.CSkip2DelimField(field_name=$a.text, base_field_name=$b.text, delim_char=$c.text)");
	                    $record_desc::theRecord.AddDerivedField(new_field, $b.text);
	                }
                   ;

field_entry[needs_len_or_end]
scope {
    needsLenOrEnd;
}
@init {
    a = None;
    f = None;
    $field_entry::needsLenOrEnd = needs_len_or_end;
}
            :   ((field_modifier) => field_modifier) ? {
                    a=$field_modifier.f_modifier;
                    f=$field_modifier.repeat_count;
                }
                b=FIELD_NAME field_def_delim_char
                c=INT
//                {$field_entry::needsLenOrEnd}?=> (field_def_delim_char d=INT NEWLINE) | NEWLINE
                ((field_def_delim_char d=INT NEWLINE)
                | NEWLINE)
                {
                    t1 = ""
                    t2 = ""
                    if $record_desc::lengthDataType == "Start_End":
                        t1 = "field_start=int(c.getText())"
                        t2 = "field_end=int(d.getText())"
                    elif $record_desc::lengthDataType == "Start_Len":
                        t1 = "field_start=int(c.getText())"
                        t2 = "field_length=int(d.getText())"
                    else:
                        #   we need some help from the Record object
                        start_pos = $record_desc::theRecord.GetNextFieldOffset();
                        t1 = "field_start=\%s" \% start_pos;
                        t2 = "field_length=int(c.getText())"
                        
                    new_field = eval("PY_Record_Field.C\%s\%sField(postype=$record_desc::lengthDataType, repeat_count=f, field_name=$b.text, \%s, \%s)" \
                        \% ((a if a else ""), $record_desc::recordType, t1, t2 ));
                    $record_desc::theRecord.AddField(new_field);
                }
                ;
                
empty_entry :   NEWLINE ;

field_name_list :   FIELD_NAME
                    (COMMA SPACE? FIELD_NAME)*
                    ;
                
field_modifier
returns [f_modifier, repeat_count] 
                        :
                        (LEADING_BLANKS {
                            $f_modifier = $LEADING_BLANKS.getText();
                            $repeat_count = -1;
                        }
                        | repeating_field {
                            $f_modifier = $repeating_field.repeat_label;
                            $repeat_count = $repeating_field.repeat_count;
                        }
                        )
                        field_def_delim_char
                        ;
                        
repeating_field
returns [repeat_label, repeat_count]
                        : INT {$repeat_count = int($INT.getText());}
                        REPEATING_FIELD {$repeat_label = $REPEATING_FIELD.getText(); }
                        ;
                        
field_separator_char :  COMMA_WORD
                        | SPACE_WORD
                        | '\|'
                        | ':'
                        | '-'
                        ;
                        
field_def_delim_char :  COMMA
                    | TAB
                    ;
                    
field_table_delim : COMMA_WORD
                    | TAB_WORD
                    ;
                    
variable_record_delim : TAB_WORD
                        | COMMA_WORD
                        ;
                        
/*------------------------------------------------------------------
 * LEXER RULES
 *------------------------------------------------------------------*/
 
LINE_COMMENT    :  '//'
                    ~('\n'|'\r')*
                    NEWLINE
                    {$channel=HIDDEN;}
                    ;

NEWLINE         :   '\r'?
                    '\n'
                    ;
            
FIXED_RECORD    :   'Fixed' ;

VARIABLE_RECORD :   'Variable' ;

FIXED_TAGGED_RECORD :   'FixedTagged' ;

UNION_RECORD    :   'Union' ;

TAGGED_HEADER :   '||TAGS||' NEWLINE ;

COMMA_WORD      :   'Comma';

TAB_WORD        :   'Tab';

SPACE_WORD      :   'Spc';

STARTEND        :   'Start_End';

STARTLEN        :   'Start_Len';

LENONLY         :   'Len';

YES             :   'Yes';

NO              :    'No';

INT             :   ('0'..'9')+ ;

LEADING_BLANKS  :   'LB';

REPEATING_FIELD :   'RP';

NAME            :   'Name';

NUMBER          :   'Number';

COMBO           :   'Combo' ;

SYNTH           :   'SYNTH';

SKIP2DELIM      :   'Skip2Delim' ;

FIELD_NAME      :   ('a'..'z' | 'A'..'Z') ('a'..'z' | 'A'..'Z' | '0'..'9' | '_' | '-')* ;

ORG_HEADER      :   'ORG * ';


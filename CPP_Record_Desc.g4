/*

    multiple Python statements in actions need to be on separate lines
    otherwise, they run together in the generated code and cause
    Python syntax errors which show up when the module is executed.
    
*/

 
grammar CPP_Record_Desc ;

/* options { */
/*     language=Cpp; */
/* } */

/*------------------------------------------------------------------
 * PARSER RULES
 *------------------------------------------------------------------*/

record_desc :   (fixed_record
                | variable_record
                | fixed_tagged_record
                | union_record)
                EOF
                ;

fixed_record :  FIXED_RECORD
                NEWLINE 
                field_names_used
                NEWLINE
                fixed_header
                field_list
                ;

variable_record :   VARIABLE_RECORD
                    NEWLINE
                    variable_header
                    ;
                    
fixed_tagged_record :   FIXED_TAGGED_RECORD
                        NEWLINE
                        field_names_used
                        NEWLINE
                        fixed_header
                        field_list
                        TAGGED_HEADER
                        YES
                        NEWLINE
                        INT
                        NEWLINE
                        tag_list
                        ;

union_record :  UNION_RECORD
                NEWLINE
                union_header
                ;


fixed_header :  length_data_type
                COMMA
                field_table_delim
                NEWLINE
                buffer_length
                NEWLINE
                ;

variable_header :   variable_record_delim ;


union_header :  variable_record_delim ;

field_names_used :  YES
                    | NO
                    ;

length_data_type :  STARTEND
                    | STARTLEN
                    | LENONLY
                    ;

buffer_length : INT ;

field_list :    field_entry
                (
                    (field_type
                    | field_start_reset)
                    | NEWLINE
                )*
                ;

field_type :    combo_field
                | synth_field
                | skip2delim_field
                | field_entry
                ;
                
tag_list :  NEWLINE* tag_field
                (combo_field
                | synth_field
                | skip2delim_field
                | tag_field
                | NEWLINE)*
                ;

field_start_reset : ORG_HEADER
                    ;

tag_field :   (field_modifier) ? 
                FIELD_NAME
                NEWLINE
                ;
            
combo_field :   COMBO
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
                
synth_field :   SYNTH
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
                   FIELD_NAME
                   field_def_delim_char
                   (NAME | NUMBER)
                   field_def_delim_char
                   field_separator_char
                   field_def_delim_char
                   FIELD_NAME
	               NEWLINE
                   ;

field_entry :   (field_modifier) ?
                FIELD_NAME field_def_delim_char
                INT
                ((field_def_delim_char INT NEWLINE) | NEWLINE)
                ;
                
empty_entry :   NEWLINE ;

field_name_list :   FIELD_NAME
                    (COMMA SPACE? FIELD_NAME)*
                    ;
                
field_modifier :    (LEADING_BLANKS | repeating_field)
                    field_def_delim_char
                    ;
                        
repeating_field : INT REPEATING_FIELD
                        ;
                        
field_separator_char :  COMMA_WORD
                        | SPACE_WORD
                        /* | '\|' */
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
 
COMMA : ',' ;
TAB :   '\t';
SPACE : ' ';
COLON : ':';
DASH : '-';

LINE_COMMENT    :  '//'
                    ~('\n'|'\r')*
                    NEWLINE
                    -> channel(HIDDEN)
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


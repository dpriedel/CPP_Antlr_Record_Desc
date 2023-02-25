/*
    NOTE: Empty lines are NOT allowed in record description files
    because I can't find a good way to handle them in Antlr4.
    So...use comment lines (//) instead.
    
*/

 
grammar CPP_Record_Desc ;

/*------------------------------------------------------------------
 * PARSER RULES
 *------------------------------------------------------------------*/

record_desc :   fixed_record
                | variable_record
                | fixed_tagged_record
                | quoted_record
                | union_record
                EOF
                ;

fixed_record :  FIXED_RECORD
                NEWLINE 
                fixed_header
                field_list
                ;

variable_record :   VARIABLE_RECORD
                    NEWLINE
                    variable_header
                    variable_field_name_list  
                    (synth_field | combo_field | skip2delim_field)*
                    ;
                    
fixed_tagged_record :   FIXED_TAGGED_RECORD
                        NEWLINE
                        fixed_header
                        field_list
                        TAGGED_HEADER
                        /* field names are required */
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

quoted_record :  QUOTED_RECORD
                NEWLINE
                quoted_header
                variable_field_name_list  
                /* END */
                /* NEWLINE */
                (synth_field | combo_field)*
                ;


fixed_header :  field_names_used
                NEWLINE
                length_data_type
                COMMA
                field_table_delim
                NEWLINE
                buffer_length
                NEWLINE
                ;

variable_header : field_names_used
                NEWLINE
                variable_record_delim
                NEWLINE
// INT value is count of actual fields in record
// excluding Virtual fields
                a=INT
                NEWLINE
                ;


union_header :  variable_record_delim ;

quoted_header : field_names_used
                NEWLINE
                variable_record_delim COMMA quote_char NEWLINE
                INT
                NEWLINE
                ;

variable_field_name_list :   (variable_list_field_name NEWLINE)*
                            ;
                
variable_list_field_name :  FIELD_NAME
                            ;

field_names_used :  YES
                    | NO
                    | USE_HEADER
                    ;

length_data_type :  STARTEND
                    | STARTLEN
                    | LENONLY
                    ;

buffer_length : INT ;

field_list :    (combo_field
                | synth_field
                | skip2delim_field
                | field_entry
                | field_start_reset
                | NEWLINE)+
                ;
                
tag_list :      (tag_field
                | combo_field
                | synth_field
                | skip2delim_field
                | NEWLINE)+
                ;

field_start_reset : ORG_HEADER
                    (FIELD_NAME | INT)
                    NEWLINE
                    ;

tag_field :   (field_modifier) ? 
                FIELD_NAME
                NEWLINE
                ;
            
combo_field :   COMBO
                field_def_delim_char
                FIELD_NAME
                field_def_delim_char
                (NAME_WORD | NUMBER_WORD)
                field_def_delim_char
                (field_separator_char)?
                field_def_delim_char
                virtual_field_name_list
                NEWLINE
                ;
                
synth_field :   SYNTH
                field_def_delim_char
                synth_field_name
                field_def_delim_char
                (NAME_WORD | NUMBER_WORD)
                field_def_delim_char
                field_separator_char
                field_def_delim_char
                virtual_field_name_list
                NEWLINE
                ;

// synth field name can have leading underscore(s)

synth_field_name : '_'* FIELD_NAME
                    ;

skip2delim_field
               :   SKIP2DELIM 
                   field_def_delim_char
                   FIELD_NAME
                   field_def_delim_char
                   (NAME_WORD | NUMBER_WORD)
                   field_def_delim_char
                   field_separator_char
                   field_def_delim_char
                   FIELD_NAME
	               NEWLINE
                   ;

field_entry :   (field_modifier)?
                FIELD_NAME
                field_def_delim_char
                a=INT
                (field_def_delim_char b=INT)?
                NEWLINE
                ;
                
empty_entry :   NEWLINE ;

virtual_field_name_list :   virtual_list_field_name
                            (COMMA virtual_list_field_name)*
                            ;
                
virtual_list_field_name :   FIELD_NAME
                    ;

field_modifier :    (LEADING_BLANKS | repeating_field)
                    field_def_delim_char
                    ;
                        
repeating_field : INT REPEATING_FIELD
                        ;
                        
field_separator_char :  COMMA_WORD
                        | SPACE_WORD
                        | TAB_WORD
                        | '|'
                        | ':'
                        | '-'
                        | '~'
                        | '/'
                        ;
                        
field_def_delim_char :  COMMA
                        | TAB
                        ;
                    
field_table_delim : COMMA_WORD
                    | TAB_WORD
                    ;

quote_char :    '"'
                | '\''
                ;
                    
variable_record_delim : TAB_WORD
                        | COMMA_WORD
                        | '|'
                        | ';'
                        ;
                        
/* quoted_record_delim :   TAB_WORD */
/*                         | COMMA_WORD */
/*                         | '|' */
/*                         ; */
                        
/*------------------------------------------------------------------
 * LEXER RULES
 *------------------------------------------------------------------*/
 
COMMA : ',' ;

TAB :   '\t';

SPACE : ' ' -> channel(HIDDEN) ;

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

QUOTED_RECORD   :   'Quoted' ;

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

USE_HEADER      :   'Header';

END             :   'END';

INT             :   ('0'..'9')+ ;

LEADING_BLANKS  :   'LB';

REPEATING_FIELD :   'RP';

NAME_WORD       :   'FLD_NAME';

NUMBER_WORD     :   'FLD_NUMBER';

COMBO           :   'COMBO' ;

SYNTH           :   'SYNTH';

SKIP2DELIM      :   'SKIP2DELIM' ;

FIELD_NAME      :   ('a'..'z' | 'A'..'Z') ('a'..'z' | 'A'..'Z' | '0'..'9' | '_' | '-')* ;

ORG_HEADER      :   'ORG * ';


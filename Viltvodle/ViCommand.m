#import "ViCommand.h"
#import "logging.h"

#define has_flag(key, flag) ((((key)->flags) & flag) == flag)

#define VIF_NEED_MOTION	(1 << 0)
#define VIF_IS_MOTION	(1 << 1)
#define VIF_SETS_DOT	(1 << 2)
#define VIF_LINE_MODE	(1 << 3)
#define VIF_NEED_CHAR	(1 << 4)

static struct vikey insert_keys[] = {
	{@"input_character:",	0x00, 0}, // default action for unknown key
	{@"decrease_indent:",	0x04, 0}, // ctrl-d
	{@"input_backspace:",	0x08, 0}, // ctrl-h
	{@"input_tab:",		0x09, 0}, // tab
	{@"input_newline:",	0x0A, 0}, // newline (ctrl-j)
	{@"input_newline:",	0x0D, 0}, // newline (ctrl-m)
	{@"increase_indent:",	0x14, 0}, // ctrl-t
	{@"literal_next:",	0x16, VIF_NEED_CHAR}, // ctrl-v
	{@"complete:",		0x18, 0}, // ctrl-x
	{@"normal_mode:",	0x1B, 0}, // escape
	{@"input_backspace:",	0x7F, 0}, // backspace
	{@"input_forward_delete:", NSDeleteFunctionKey, 0}, // forward delete
	{@"move_left:",		NSLeftArrowFunctionKey, VIF_IS_MOTION},
	{@"move_down:",		NSDownArrowFunctionKey, VIF_IS_MOTION | VIF_LINE_MODE},
	{@"move_up:",		NSUpArrowFunctionKey, VIF_IS_MOTION | VIF_LINE_MODE},
	{@"move_right:",	NSRightArrowFunctionKey, VIF_IS_MOTION},
	{@"backward_screen:",	NSPageUpFunctionKey, VIF_IS_MOTION}, // ^B
	{@"forward_screen:",	NSPageDownFunctionKey, VIF_IS_MOTION}, // ^F
	{@"move_first_char:",	NSHomeFunctionKey, VIF_IS_MOTION},
	{@"move_eol:",		NSEndFunctionKey, VIF_IS_MOTION},
	{nil, -1, 0}
};

static struct vikey window_keys[] = {
	{@"illegal:",		0x00, 0}, // default action for unknown key
	{@"window_left:",	0x8, 0},	// ^H
	{@"window_down:",	0xA, 0},	// ^J
	{@"window_up:",		0xB, 0},	// ^K
	{@"window_right:",	0xC, 0},	// ^L
	{@"window_new:",	0xE, 0},	// ^N
	{@"window_totab:",	'T', 0},
	{@"window_close:",	'c', 0},
	{@"window_left:",	'h', 0},
	{@"window_down:",	'j', 0},
	{@"window_up:",		'k', 0},
	{@"window_right:",	'l', 0},
	{@"window_new:",	'n', 0},
	{@"window_only:",	'o', 0},
	{@"window_split:",	's', 0},
	{@"window_vsplit:",	'v', 0},
	{@"window_normalize:",	'=', 0},
	{@"window_left:",	NSLeftArrowFunctionKey, 0},
	{@"window_down:",	NSDownArrowFunctionKey, 0},
	{@"window_up:",		NSUpArrowFunctionKey, 0},
	{@"window_right:",	NSRightArrowFunctionKey, 0},
	{nil, -1, 0}
};

static struct vikey g_keys[] = {
	{@"illegal:",		0x00, 0}, // default action for unknown key
	{@"goto_line:",		'g', VIF_IS_MOTION | VIF_LINE_MODE},
	{@"uppercase:",		'U', VIF_NEED_MOTION | VIF_SETS_DOT},
	{@"lowercase:",		'u', VIF_NEED_MOTION | VIF_SETS_DOT},
	{@"next_tab:",		't', 0},
	{@"previous_tab:",	'T', 0},
	{nil, -1, 0}
};

static struct vikey visual_g_keys[] = {
	{@"illegal:",		0x00, 0}, // default action for unknown key
	{@"goto_line:",		'g', VIF_IS_MOTION | VIF_LINE_MODE},
	{@"uppercase:",		'U', VIF_SETS_DOT},
	{@"lowercase:",		'u', VIF_SETS_DOT},
	{@"next_tab:",		't', 0},
	{@"previous_tab:",	'T', 0},
	{nil, -1, 0}
};

static struct vikey operator_g_keys[] = {
	{@"nonmotion:",		0x00, 0}, // default action for unknown key
	{@"goto_line:",		'g', VIF_IS_MOTION | VIF_LINE_MODE},
	{nil, -1, 0}
};

static struct vikey normal_keys[] = {
	{@"illegal:",		0x00, 0}, // default action for unknown key
	{@"find_current_word:",	0x1, VIF_IS_MOTION}, // ^A
	{@"backward_screen:",	0x2, VIF_IS_MOTION}, // ^B
	{@"scroll_downward:",	0x4, 0}, // ^D
	{@"scroll_down_by_line:",0x5, 0}, // ^E
	{@"forward_screen:",	0x6, VIF_IS_MOTION}, // ^F
	{@"move_left:",		0x8, VIF_IS_MOTION}, // ^H
	{@"jumplist_forward:",	0x9, 0},  // ^I
	{@"move_down:",		0xA, VIF_IS_MOTION | VIF_LINE_MODE},  // ^J
	{@"move_down:",		0xD, VIF_IS_MOTION | VIF_LINE_MODE},  // ^M
	{@"jumplist_backward:",	0xF, 0},  // ^O
	{@"show_info:",		0x7, 0},  // ^G
	{@"vim_redo:",		0x12, 0}, // ^R
	{@"pop_tag:",		0x14, 0}, // ^T
	{@"scroll_upwards:",	0x15, 0}, // ^U
	{@"window_prefix:",	0x17, 0, window_keys}, // ^W
	{@"scroll_up_by_line:",	0x19, 0}, // ^Y
	{@"normal_mode:",	0x1B, 0}, // escape
	{@"jump_tag:",		0x1D, 0}, // ^]
	{@"switch_file:",	0x1E, 0}, // ^^
	{@"move_left:",		0x7F, VIF_IS_MOTION}, // backspace
	{@"move_right:",	' ', VIF_IS_MOTION},
	{@"append_eol:",	'A', VIF_SETS_DOT},
	{@"word_backward:",	'B', VIF_IS_MOTION},
	{@"change_eol:",	'C', VIF_SETS_DOT},
	{@"delete_eol:",	'D', VIF_SETS_DOT},
	{@"end_of_word:",	'E', VIF_IS_MOTION},
	{@"move_back_to_char:",	'F', VIF_IS_MOTION | VIF_NEED_CHAR},
	{@"goto_line:",		'G', VIF_IS_MOTION | VIF_LINE_MODE},
	{@"move_high:",		'H', VIF_IS_MOTION | VIF_LINE_MODE},
	{@"insert_bol:",	'I', VIF_SETS_DOT},
	{@"join:",		'J', VIF_SETS_DOT},
	{@"move_low:",		'L', VIF_IS_MOTION | VIF_LINE_MODE},
	{@"move_middle:",	'M', VIF_IS_MOTION | VIF_LINE_MODE},
	{@"repeat_find_backward:",'N', VIF_IS_MOTION},
	{@"open_line_above:",	'O', VIF_SETS_DOT},
	{@"put_before:",	'P', VIF_SETS_DOT},
	{@"subst_lines:",	'S', VIF_LINE_MODE | VIF_SETS_DOT},
	{@"move_back_til_char:",'T', VIF_IS_MOTION | VIF_NEED_CHAR},
	{@"visual_line:",	'V', 0},
	{@"word_forward:",	'W', VIF_IS_MOTION},
	{@"delete_backward:",	'X', VIF_SETS_DOT},
	{@"yank:",		'Y', VIF_LINE_MODE | VIF_SETS_DOT},
	{@"move_bol:",		'0', VIF_IS_MOTION},
	{@"append:",		'a', VIF_SETS_DOT},
	{@"word_backward:",	'b', VIF_IS_MOTION},
	{@"change:",		'c', VIF_NEED_MOTION | VIF_SETS_DOT},
	{@"delete:",		'd', VIF_NEED_MOTION | VIF_SETS_DOT},
	{@"end_of_word:",	'e', VIF_IS_MOTION},
	{@"move_to_char:",	'f', VIF_IS_MOTION | VIF_NEED_CHAR},
	{@"g_prefix:",		'g', 0, g_keys},
	{@"move_left:",		'h', VIF_IS_MOTION},
	{@"insert:",		'i', VIF_SETS_DOT},
	{@"move_down:",		'j', VIF_IS_MOTION | VIF_LINE_MODE},
	{@"move_up:",		'k', VIF_IS_MOTION | VIF_LINE_MODE},
	{@"move_right:",	'l', VIF_IS_MOTION},
	{@"set_mark:",		'm', VIF_NEED_CHAR},
	{@"repeat_find:",	'n', VIF_IS_MOTION},
	{@"open_line_below:",	'o', VIF_SETS_DOT},
	{@"put_after:",		'p', VIF_SETS_DOT},
	{@"replace:",		'r', VIF_SETS_DOT | VIF_NEED_CHAR},
	{@"substitute:",	's', VIF_SETS_DOT},
	{@"move_til_char:",	't', VIF_IS_MOTION | VIF_NEED_CHAR},
	{@"vi_undo:",		'u', 0},
	{@"visual:",		'v', 0},
	{@"word_forward:",	'w', VIF_IS_MOTION},
	{@"delete_forward:",	'x', VIF_SETS_DOT},
	{@"yank:",		'y', VIF_NEED_MOTION | VIF_SETS_DOT},
	{@"move_eol:",		'$', VIF_IS_MOTION},
	{@"move_first_char:",	'_', VIF_IS_MOTION | VIF_LINE_MODE},
	{@"move_first_char:",	'^', VIF_IS_MOTION},
	{@"ex_command:",	':', 0},
	{@"repeat_line_search_forward:", ';', VIF_IS_MOTION},
	{@"repeat_line_search_backward:", ',', VIF_IS_MOTION},
	{@"shift_right:",	'>', VIF_SETS_DOT | VIF_NEED_MOTION | VIF_LINE_MODE},
	{@"shift_left:",	'<', VIF_SETS_DOT | VIF_NEED_MOTION | VIF_LINE_MODE},
	{@"find:",		'/', VIF_IS_MOTION},
	{@"find_backwards:",	'?', VIF_IS_MOTION},
	{@"find_current_word_backward:",'#', VIF_IS_MOTION},
	{@"find_current_word_forward:",	'*', VIF_IS_MOTION},
	{@"paragraph_forward:",	'}', VIF_IS_MOTION},
	{@"paragraph_backward:",'{', VIF_IS_MOTION},
	{@"filter:",		'!', VIF_SETS_DOT | VIF_NEED_MOTION},
	{@"move_to_match:",	'%', VIF_IS_MOTION},
	{@"move_to_mark:",	'\'', VIF_NEED_CHAR | VIF_IS_MOTION},
	{@"move_to_mark:",	'`', VIF_NEED_CHAR | VIF_IS_MOTION},
	{@"dot:",		'.', 0},
	{@"move_left:",		NSLeftArrowFunctionKey, VIF_IS_MOTION},
	{@"move_down:",		NSDownArrowFunctionKey, VIF_IS_MOTION | VIF_LINE_MODE},
	{@"move_up:",		NSUpArrowFunctionKey, VIF_IS_MOTION | VIF_LINE_MODE},
	{@"move_right:",	NSRightArrowFunctionKey, VIF_IS_MOTION},
	{@"backward_screen:",	NSPageUpFunctionKey, VIF_IS_MOTION},
	{@"forward_screen:",	NSPageDownFunctionKey, VIF_IS_MOTION},
	{@"move_first_char:",	NSHomeFunctionKey, VIF_IS_MOTION},
	{@"move_eol:",		NSEndFunctionKey, VIF_IS_MOTION},
	{@"delete_forward:",	NSDeleteFunctionKey, VIF_SETS_DOT}, // forward delete
	{nil, -1, 0}
};

static struct vikey operator_keys[] = {
	{@"nonmotion:",		0x00, 0}, // default action for unknown key
	{@"find_current_word:",	0x1, VIF_IS_MOTION}, // ^A
	{@"backward_screen:",	0x2, VIF_IS_MOTION}, // ^B
	{@"forward_screen:",	0x6, VIF_IS_MOTION}, // ^F
	{@"normal_mode:",	0x1B, 0}, // escape
	{@"move_left:",		0x8, VIF_IS_MOTION}, // ^H
	{@"move_left:",		0x7F, VIF_IS_MOTION}, // backspace
	{@"move_down:",		0xA, VIF_IS_MOTION | VIF_LINE_MODE},  // ^J
	{@"move_down:",		0xD, VIF_IS_MOTION | VIF_LINE_MODE},  // ^M
	{@"move_right:",	' ', VIF_IS_MOTION},
	{@"word_backward:",	'B', VIF_IS_MOTION},
	{@"end_of_word:",	'E', VIF_IS_MOTION},
	{@"move_back_to_char:",	'F', VIF_IS_MOTION | VIF_NEED_CHAR},
	{@"goto_line:",		'G', VIF_IS_MOTION | VIF_LINE_MODE},
	{@"move_high:",		'H', VIF_IS_MOTION | VIF_LINE_MODE},
	{@"move_low:",		'L', VIF_IS_MOTION | VIF_LINE_MODE},
	{@"move_middle:",	'M', VIF_IS_MOTION | VIF_LINE_MODE},
	{@"repeat_find_backward:",'N', VIF_IS_MOTION},
	{@"move_back_til_char:",'T', VIF_IS_MOTION | VIF_NEED_CHAR},
	{@"word_forward:",	'W', VIF_IS_MOTION},
	{@"move_bol:",		'0', VIF_IS_MOTION},
	{@"select_outer:",	'a', VIF_IS_MOTION | VIF_NEED_CHAR},
	{@"word_backward:",	'b', VIF_IS_MOTION},
	{@"end_of_word:",	'e', VIF_IS_MOTION},
	{@"move_to_char:",	'f', VIF_IS_MOTION | VIF_NEED_CHAR},
	{@"g_prefix:",		'g', 0, operator_g_keys},
	{@"move_left:",		'h', VIF_IS_MOTION},
	{@"select_inner:",	'i', VIF_IS_MOTION | VIF_NEED_CHAR},
	{@"move_down:",		'j', VIF_IS_MOTION | VIF_LINE_MODE},
	{@"move_up:",		'k', VIF_IS_MOTION | VIF_LINE_MODE},
	{@"move_right:",	'l', VIF_IS_MOTION},
	{@"repeat_find:",	'n', VIF_IS_MOTION},
	{@"move_til_char:",	't', VIF_IS_MOTION | VIF_NEED_CHAR},
	{@"word_forward:",	'w', VIF_IS_MOTION},
	{@"move_eol:",		'$', VIF_IS_MOTION},
	{@"move_first_char:",	'_', VIF_IS_MOTION | VIF_LINE_MODE},
	{@"move_first_char:",	'^', VIF_IS_MOTION},
	{@"repeat_line_search_forward:", ';', VIF_IS_MOTION},
	{@"repeat_line_search_backward:", ',', VIF_IS_MOTION},
	{@"find:",		'/', VIF_IS_MOTION},
	{@"find_backwards:",	'?', VIF_IS_MOTION},
	{@"find_current_word_backward:",'#', VIF_IS_MOTION},
	{@"find_current_word_forward:",	'*', VIF_IS_MOTION},
	{@"paragraph_forward:",	'}', VIF_IS_MOTION},
	{@"paragraph_backward:",'{', VIF_IS_MOTION},
	{@"move_to_match:",	'%', VIF_IS_MOTION},
	{@"move_to_mark:",	'\'', VIF_IS_MOTION | VIF_NEED_CHAR},
	{@"move_to_mark:",	'`', VIF_IS_MOTION | VIF_NEED_CHAR},
	{@"move_left:",		NSLeftArrowFunctionKey, VIF_IS_MOTION},
	{@"move_down:",		NSDownArrowFunctionKey, VIF_IS_MOTION | VIF_LINE_MODE},
	{@"move_up:",		NSUpArrowFunctionKey, VIF_IS_MOTION | VIF_LINE_MODE},
	{@"move_right:",	NSRightArrowFunctionKey, VIF_IS_MOTION},
	{@"backward_screen:",	NSPageUpFunctionKey, VIF_IS_MOTION}, // ^B
	{@"forward_screen:",	NSPageDownFunctionKey, VIF_IS_MOTION}, // ^F
	{@"move_first_char:",	NSHomeFunctionKey, VIF_IS_MOTION},
	{@"move_eol:",		NSEndFunctionKey, VIF_IS_MOTION},
	{nil, -1, 0}
};

static struct vikey visual_keys[] = {
	{@"illegal:",		0x00, 0}, // default action for unknown key
	{@"find_current_word:",	0x1, VIF_IS_MOTION}, // ^A, FIXME: vim binds this to increment number
	{@"backward_screen:",	0x2, VIF_IS_MOTION}, // ^B
	{@"forward_screen:",	0x6, VIF_IS_MOTION}, // ^F
	{@"normal_mode:",	0x1B, 0}, // escape
	{@"move_left:",		0x8, VIF_IS_MOTION}, // ^H
	{@"delete:",		0x7F, VIF_IS_MOTION}, // backspace
	{@"move_down:",		0xA, VIF_IS_MOTION | VIF_LINE_MODE},  // ^J
	{@"move_down:",		0xD, VIF_IS_MOTION | VIF_LINE_MODE},  // ^M
	{@"move_right:",	' ', VIF_IS_MOTION},
	{@"append_eol:",	'A', VIF_SETS_DOT},
	{@"word_backward:",	'B', VIF_IS_MOTION},
	{@"change:",		'C', VIF_SETS_DOT | VIF_LINE_MODE},
	{@"delete:",		'D', VIF_SETS_DOT | VIF_LINE_MODE},
	{@"end_of_word:",	'E', VIF_IS_MOTION},
	{@"move_back_to_char:",	'F', VIF_IS_MOTION | VIF_NEED_CHAR},
	{@"goto_line:",		'G', VIF_IS_MOTION | VIF_LINE_MODE},
	{@"move_high:",		'H', VIF_IS_MOTION | VIF_LINE_MODE},
	{@"insert_bol:",	'I', VIF_SETS_DOT},
	{@"join:",		'J', VIF_SETS_DOT},
	{@"move_low:",		'L', VIF_IS_MOTION | VIF_LINE_MODE},
	{@"move_middle:",	'M', VIF_IS_MOTION | VIF_LINE_MODE},
	{@"repeat_find_backward:",'N', VIF_IS_MOTION},
	{@"visual_other_corner:",'O', 0},
	{@"put_before:",	'P', VIF_SETS_DOT},
	{@"subst_lines:",	'S', VIF_LINE_MODE | VIF_SETS_DOT},
	{@"move_back_til_char:",'T', VIF_IS_MOTION | VIF_NEED_CHAR},
	{@"uppercase:",		'U', VIF_SETS_DOT},
	{@"visual_line:",	'V', 0},
	{@"word_forward:",	'W', VIF_IS_MOTION},
	{@"delete:",		'X', VIF_SETS_DOT | VIF_LINE_MODE},
	{@"move_bol:",		'0', VIF_IS_MOTION},
	{@"select_outer:",	'a', VIF_IS_MOTION | VIF_NEED_CHAR},
	{@"word_backward:",	'b', VIF_IS_MOTION},
	{@"change:",		'c', VIF_SETS_DOT},
	{@"delete:",		'd', VIF_SETS_DOT},
	{@"end_of_word:",	'e', VIF_IS_MOTION},
	{@"move_to_char:",	'f', VIF_IS_MOTION | VIF_NEED_CHAR},
	{@"g_prefix:",		'g', 0, visual_g_keys},
	{@"move_left:",		'h', VIF_IS_MOTION},
	{@"select_inner:",	'i', VIF_IS_MOTION | VIF_NEED_CHAR},
	{@"move_down:",		'j', VIF_IS_MOTION | VIF_LINE_MODE},
	{@"move_up:",		'k', VIF_IS_MOTION | VIF_LINE_MODE},
	{@"move_right:",	'l', VIF_IS_MOTION},
	{@"set_mark:",		'm', VIF_NEED_CHAR},
	{@"repeat_find:",	'n', VIF_IS_MOTION},
	{@"visual_other_end:",	'o', VIF_SETS_DOT},
	{@"put_after:",		'p', VIF_SETS_DOT},
	{@"replace:",		'r', VIF_SETS_DOT | VIF_NEED_CHAR},
	{@"change:",		's', VIF_SETS_DOT},
	{@"move_til_char:",	't', VIF_IS_MOTION | VIF_NEED_CHAR},
	{@"lowercase:",		'u', VIF_SETS_DOT},
	{@"visual:",		'v', 0},
	{@"word_forward:",	'w', VIF_IS_MOTION},
	{@"delete:",		'x', VIF_SETS_DOT},
	{@"yank:",		'y', VIF_SETS_DOT},
	{@"move_eol:",		'$', VIF_IS_MOTION},
	{@"move_first_char:",	'_', VIF_IS_MOTION | VIF_LINE_MODE},
	{@"move_first_char:",	'^', VIF_IS_MOTION},
	{@"ex_command:",	':', 0},
	{@"shift_right:",	'>', VIF_SETS_DOT | VIF_LINE_MODE},
	{@"shift_left:",	'<', VIF_SETS_DOT | VIF_LINE_MODE},
	{@"find:",		'/', VIF_IS_MOTION},
	{@"find_backwards:",	'?', VIF_IS_MOTION},
	{@"find_current_word_backward:",'#', VIF_IS_MOTION},
	{@"find_current_word_forward:",	'*', VIF_IS_MOTION},
	{@"paragraph_forward:",	'}', VIF_IS_MOTION},
	{@"paragraph_backward:",'{', VIF_IS_MOTION},
	{@"filter:",		'!', VIF_SETS_DOT},
	{@"move_to_match:",	'%', VIF_IS_MOTION},
	{@"move_to_mark:",	'\'', VIF_NEED_CHAR | VIF_IS_MOTION},
	{@"move_to_mark:",	'`', VIF_NEED_CHAR | VIF_IS_MOTION},
	{@"delete:",		NSDeleteFunctionKey, 0},
	{@"move_left:",		NSLeftArrowFunctionKey, VIF_IS_MOTION},
	{@"move_down:",		NSDownArrowFunctionKey, VIF_IS_MOTION | VIF_LINE_MODE},
	{@"move_up:",		NSUpArrowFunctionKey, VIF_IS_MOTION | VIF_LINE_MODE},
	{@"move_right:",	NSRightArrowFunctionKey, VIF_IS_MOTION},
	{@"backward_screen:",	NSPageUpFunctionKey, VIF_IS_MOTION}, // ^B
	{@"forward_screen:",	NSPageDownFunctionKey, VIF_IS_MOTION}, // ^F
	{@"move_first_char:",	NSHomeFunctionKey, VIF_IS_MOTION},
	{@"move_eol:",		NSEndFunctionKey, VIF_IS_MOTION},
	{nil, -1, 0}
};

static struct vikey explorer_d_keys[] = {
	{@"illegal:",		0x00, 0}, // default action for unknown key
	{@"remove_files:",	'd', 0},
	{nil, -1, 0}
};

static struct vikey explorer_keys[] = {
	{@"illegal:",		0x00, 0}, // default action for unknown key
	{@"backward_screen:",	0x2, VIF_IS_MOTION}, // ^B
	{@"scroll_downward:",	0x4, 0}, // ^D
	{@"scroll_down_by_line:",0x5, 0}, // ^E
	{@"forward_screen:",	0x6, VIF_IS_MOTION}, // ^F
	{@"move_left:",		0x8, VIF_IS_MOTION}, // ^H
	{@"rescan_files:",	0xC, 0}, // ^L
	{@"tab_open:",		0xD, VIF_IS_MOTION},  // ^M
	{@"scroll_upwards:",	0x15, 0}, // ^U
	{@"scroll_up_by_line:",	0x19, 0}, // ^Y
	{@"cancel_explorer:",	0x1B, 0}, // escape
	{@"goto_line:",		'G', VIF_IS_MOTION},
	{@"move_high:",		'H', VIF_IS_MOTION},
	{@"move_low:",		'L', VIF_IS_MOTION},
	{@"move_middle:",	'M', VIF_IS_MOTION},
	{@"new_folder:",	'N', 0},
	{@"d_prefix:",		'd', 0, explorer_d_keys},	// make dd remove files
	{@"g_prefix:",		'g', 0, operator_g_keys},	// XXX
	{@"move_left:",		'h', VIF_IS_MOTION},
	{@"move_down:",		'j', VIF_IS_MOTION},
	{@"move_up:",		'k', VIF_IS_MOTION},
	{@"move_right:",	'l', VIF_IS_MOTION},
	{@"new_document:",	'n', 0},
	{@"switch_open:",	'o', 0},
	{@"split_open:",	's', 0},
	{@"tab_open:",		't', 0},
	{@"vsplit_open:",	'v', 0},
	{@"find:",		'/', VIF_IS_MOTION},
	{@"move_left:",		NSLeftArrowFunctionKey, VIF_IS_MOTION},
	{@"move_down:",		NSDownArrowFunctionKey, VIF_IS_MOTION},
	{@"move_up:",		NSUpArrowFunctionKey, VIF_IS_MOTION},
	{@"move_right:",	NSRightArrowFunctionKey, VIF_IS_MOTION},
	{@"backward_screen:",	NSPageUpFunctionKey, VIF_IS_MOTION},
	{@"forward_screen:",	NSPageDownFunctionKey, VIF_IS_MOTION},
	{@"move_home:",		NSHomeFunctionKey, VIF_IS_MOTION},
	{@"move_end:",		NSEndFunctionKey, VIF_IS_MOTION},
	{nil, -1, 0}
};

static struct vikey *
find_command_in_map(unichar key, struct vikey map[])
{
	int i;
	for (i = 0; map[i].method; i++)
		if (map[i].key == key)
			return &map[i];

	/* Return the default action if not found already. */
	if (key != 0)
		return find_command_in_map(0, map);

	return NULL;
}

@implementation ViCommand

@synthesize complete;
@synthesize partial;
@synthesize method;
@synthesize count;
@synthesize motion_count;
@synthesize key;
@synthesize motion_key;
@synthesize argument;
@synthesize is_dot;
@synthesize text;
@synthesize nviStyleUndo;
@synthesize last_ftFT_command;
@synthesize last_ftFT_argument;
@synthesize last_search_pattern;
@synthesize last_search_options;

/* finalizes the command, sets the dot command and adjusts counts if necessary
 */
- (void)setComplete
{
	complete = YES;
	partial = NO;

	DEBUG(@"complete, command = %@, count = %li", command->method, count);

	if (command && command->key == '.') {
		is_dot = YES;

		/* From nvi:
		 * !!!
		 * If a '.' is immediately entered after an undo command, we
		 * replay the log instead of redoing the last command.  This
		 * is necessary because 'u' can't set the dot command -- see
		 * vi/v_undo.c:v_undo for details.
		 */
		if (nviStyleUndo && last_command && last_command->key == 'u') {
			command = last_command;
			method = last_command->method;
			key = last_command->key;
		} else {
			if (dot_command == nil) {
				method = @"nodot:"; // prints "No command to repeat"
				command = NULL;
				motion_command = NULL;
			} else {
				command = dot_command;
				if (count == 0)
					count = dot_count;
				method = dot_command->method;
				motion_command = dot_motion_command;
				motion_count = dot_motion_count;
				key = dot_command->key;
				argument = dot_argument;
				if (dot_motion_command)
					motion_key = dot_motion_command->key;
			}
		}
	}

	last_command = command;

	if (command && has_flag(command, VIF_SETS_DOT)) {
		/* set the dot command parameters */
		dot_command = command;
		dot_motion_command = motion_command;
		dot_count = count;
		dot_motion_count = motion_count;
		dot_argument = argument;

		/* new (real) commands reset the associated text */
		if (!is_dot)
			[self setText:nil];
	}

	if (command && (command->key == 't' || command->key == 'f' ||
	    command->key == 'T' || command->key == 'F')) {
		last_ftFT_command = command->key;
		last_ftFT_argument = argument;
	}

	if (motion_command && (motion_command->key == 't' || motion_command->key == 'f' ||
	    motion_command->key == 'T' || motion_command->key == 'F')) {
		last_ftFT_command = motion_command->key;
		last_ftFT_argument = argument;
	}

	if (count > 0 && motion_count > 0) {
		/* From nvi:
		 * A count may be provided both to the command and to the motion, in
		 * which case the count is multiplicative.  For example ,"3y4y" is the
		 * same as "12yy".  This count is provided to the motion command and 
		 * not to the regular function.
		 */
		motion_count *= count;
		count = 0;
	} else if (count > 0 && motion_count == 0 && motion_command != NULL) {
		/*
		 * If a count is given to an operator command, attach the count
		 * to the motion command instead.
		 */
		motion_count = count;
		count = 0;
	}
}

- (void)pushKey:(unichar)aKey
{
	is_dot = NO;
	partial = YES;

	DEBUG(@"got key 0x%04X", aKey);

	if (state == ViCommandNeedChar) {
		argument = aKey;
		[self setComplete];
		return;
	}

	// check if it's a repeat count
	if (map != insert_keys) {
		int *countp = &count;
		if (state == ViCommandNeedMotion)
			countp = &motion_count;
		// conditionally include '0' as a repeat count only if it's not the first digit
		if (aKey >= '1' - ((countp && *countp > 0) ? 1 : 0) && aKey <= '9') {
			*countp *= 10;
			*countp += aKey - '0';
			DEBUG(@"count is now %i", count);
			return;
		}
	}

	if (state == ViCommandNeedMotion && aKey == command->key) {
		/* From nvi:
		 * Commands that have motion components can be doubled to
		 * imply the current line.
		 *
		 * Do this by setting the line mode flag.
		 */
		motion_key = aKey;
		motion_command = command;
		[self setComplete];
		return;
	}

	if (map == NULL)
		map = normal_keys;

	struct vikey *vikey = find_command_in_map(aKey, map);
	if (vikey == NULL) {
		method = @"internal_error:";
		[self setComplete];
		return;
	}

	if (state == ViCommandInitialState) {
		command = vikey;
		method = command->method;
		key = aKey;
		if (has_flag(vikey, VIF_NEED_MOTION)) {
			state = ViCommandNeedMotion;
			map = operator_keys;
		} else if (has_flag(vikey, VIF_NEED_CHAR)) {
			// VIF_NEED_CHAR and VIF_NEED_MOTION are mutually exclusive
			state = ViCommandNeedChar;
		} else if (vikey->map != NULL)
			map = vikey->map;
		else
			[self setComplete];
	} else if (state == ViCommandNeedMotion) {
		motion_key = aKey;

		if (has_flag(vikey, VIF_IS_MOTION))
			motion_command = vikey;
		else if (vikey->map == NULL) {
			// should print "X may not be used as a motion command"
			method = @"nonmotion:";
		}

		if (has_flag(vikey, VIF_NEED_CHAR))
			state = ViCommandNeedChar;
		else if (vikey->map != NULL)
			map = vikey->map;
		else
			[self setComplete];
	} else {
		method = @"internal_error:";
		[self setComplete];
		return;
	}
}

- (void)reset
{
	DEBUG(@"%s", "resetting");
	partial = NO;
	complete = NO;
	method = nil;
	command = NULL;
	motion_command = NULL;
	state = ViCommandInitialState;
	count = 0;
	motion_count = 0;
	key = -1;
	argument = -1;
	map = normal_keys;
	literal_next = NO;
}

- (BOOL)ismotion
{
	return command && has_flag(command, VIF_IS_MOTION);
}

- (BOOL)line_mode
{
	if (motion_command) {
		if (motion_command == command)
			return YES;
		return has_flag(motion_command, VIF_LINE_MODE);
	}
	return command && has_flag(command, VIF_LINE_MODE);
}

- (NSString *)motion_method
{
	if (motion_command && has_flag(motion_command, VIF_IS_MOTION))
		return motion_command->method;
	return nil;
}

- (void)setVisualMap
{
	map = visual_keys;
}

- (void)setInsertMap
{
	map = insert_keys;
}

- (void)setExplorerMap
{
	map = explorer_keys;
}

@end

@implementation ViKey
@synthesize code;
@synthesize flags;

+ (ViKey *)keyWithCode:(unichar)aCode flags:(unsigned int)aFlags
{
	return [[ViKey alloc] initWithCode:aCode flags:aFlags];
}

- (ViKey *)initWithCode:(unichar)aCode flags:(unsigned int)aFlags
{
	self = [[ViKey alloc] init];
	if (self) {
		code = aCode;
		flags = aFlags;
	}
	return self;
	
}
@end


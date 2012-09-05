/*Copyright(C)2002 - Michael D. Stemle, Jr. (mstemle1024@msn.com)
 
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.
 
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.*/


#ifndef LIBPUD
# define LIBPUD

#ifndef _GNU_SOURCE
# define _GNU_SOURCE 1
#endif //_GNU_SOURCE

#define LIBPUD_VERSION "0.1.0"

#define SUPPORTED_PUDRC_VERSION "0.1.0"

/* Set the default paths for the templates */
/* Template path */
#ifndef PUD_TEMPLATE_PATH
# define PUD_TEMPLATE_PATH "/usr/share/pud/templates/"
#endif

/* Style path */
#ifndef PUD_STYLE_PATH
# define PUD_STYLE_PATH "/usr/share/pud/styles/"
#endif

/* User template subdir (from $HOME) */
#ifndef PUD_USER_TEMPLATE_SUBDIR
# define PUD_USER_TEMPLATE_SUBDIR ".pud/templates/"
#endif

/* User style subdir (from $HOME) */
#ifndef PUD_USER_STYLE_SUBDIR
# define PUD_USER_STYLE_SUBDIR ".pud/styles/"
#endif

/* Default global config file (including path) */
#ifndef PUD_GLOBAL_CONFIG
# define PUD_GLOBAL_CONFIG "/etc/pud.conf"
#endif

/* A simple boolean type */
typedef enum {
  FALSE = 0,
  TRUE = 1
} bool_t;

/* Comment styles found in files */
typedef enum {
  CS_NONE		= 0,
  CS_SINGLE		= 1,
  CS_MULTI		= 2,
  CS_BOTH		= 3
} comment_style_t;

typedef enum {
  DOIT_NORMAL		= 0,
  DOIT_HELP		= 1,
  DOIT_VERSION		= 2
} arg_orders_t;

/* The global pud config file */
struct pud_global_config {
  char pud_version[32];
  char template_path[256];
  char style_path[256];
  char comment_index[256];
};

/* Data structure for information found within the pudrc file */
struct pudrc_data {
  char pud_version[32];
  char copyright_holder[128];
  char email_address[128];
  char default_template[64];
};

/* For the split routine */
struct split_result {
	char str[256];
	int len;
};

/* Contains information about a programming language. */
struct language_info {
  char name[16];
  comment_style_t comment_style;
  char comment_single[4];
  char comment_multi_open[4];
  char comment_multi_close[4];
};

/* Data about a template */
struct pud_template {
  char rawname[128];
  char file_name[128];
};

/* Data about a style */
struct pud_style {
  char rawname[128];
  char file_name[128];
};

/* ALL OF THESE ELEMENTS MUST BE CHARS!
   REMEMBER TO MODIFY PARSE ROUTINES UPON CHANGING THIS STRUCT! */
struct pud_output_info {
  char file_version[32];
  char file_title[128];
  char file_name[128];
  char package_name[64];
  char author_name[128];
  char author_email[128];
  char year[8];
  char template_name[64];
  struct pud_template template;
  struct pud_style style;
  arg_orders_t whattodo;
};

/* THESE DEFINES GO WITH pud_output_info STRUCT!
   Each define corrosponds to an element in the struct! */
#define POI_FILE_VERSION_TOKEN "VERSION_NUMBER"
#define POI_FILE_NAME_TOKEN "FILE"
#define POI_PACKAGE_NAME_TOKEN "PACKAGE"
#define POI_AUTHOR_NAME_TOKEN "AUTHOR"
#define POI_AUTHOR_EMAIL_TOKEN "EMAIL"
#define POI_YEAR_TOKEN "YEAR"
#define POI_UNDERLINE_FILE_TOKEN "UNDERLINE_FILE"
#define POI_TEMPLATE_TOKEN "TEMPLATE"

/* String working routines */
void chop (char *str);
void chomp (char *str);
int splitstrstr (struct split_result *target, char *str, char *delim);
char *cat_str (char *dest, char *src);
int strcpy_limit (char *dest, char *src, int limit);
char *str_replace (char *dest, char *src, char *substr, char *filler);
int get_underline_for_string (char *uline, char *str);
char *truncate_string_at_char (char *str, char chr);
char *forceUC (char *str);
char *forceLC (char *str);
char *swap_char (char *str, char replace, char with);

static bool_t pud_read_only = FALSE;

/* Pud config-based routines */
struct pud_global_config *get_global_config (struct pud_global_config *target);
struct pudrc_data *read_pudrc_file (struct pudrc_data *target, char *file_name, struct pud_global_config conf);
bool_t write_pudrc_file (struct pudrc_data data, char *fname);

/* For loading templates, styles, and the comment index */
struct language_info *get_language_info (struct language_info *dest, struct pud_global_config conf, char *lang);
char *parse_template_file (struct pud_template template, char *dest, struct pud_output_info *info);
char *parse_style_file (struct pud_style style,
			char *dest,
			struct pud_output_info *info,
			char *template,
			struct language_info *lang);

/* Applying templates, styles, and the comment index */
char *commentify_data (char *dest, char *data, struct language_info *lang);

/* Routines for easier interface */
void set_file_title (struct pud_output_info *info);
struct pud_template *get_pud_template_data (struct pud_template *target, char *str, struct pud_global_config conf);
struct pud_style *get_pud_style_data (struct pud_style *target, char *str, struct pud_global_config conf);
struct pud_output_info *parse_args (struct pud_output_info *target, char *argv[], int argc);
bool_t check_for_file (struct pud_output_info info);

/* A function to get the config data from the user */
struct pudrc_data *get_pudrc_data_from_user (struct pudrc_data *target,
					     struct pud_global_config conf,
					     bool_t use_defaults);

#endif //LIBPUD

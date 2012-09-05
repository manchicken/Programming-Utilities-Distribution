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


#ifndef _GNU_SOURCE
# define _GNU_SOURCE 1
#endif //_GNU_SOURCE

#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdio.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <time.h>
#include <dirent.h>

#include "libpud.h"

extern int errno;

void chop (char *str) {
  int index = strlen (str);

  str[index] = '\0';

  return;
}

void chomp (char *str) {
  int x = strlen (str) - 1;

  while (x > 0 && (str[x] == '\r' ||
				   str[x] == '\n')) {
	str[x--] = '\0';
  }

  return;
}

/* This function assumes that char **target is already allocated to the size it should be allocated. */
int splitstrstr (struct split_result *target, char *str, char *delim) {
  int dlimsiz = strlen (delim);
  int strsiz = strlen (str);
  char *ptr = (char *) NULL;
  char *test = (char *) malloc ((dlimsiz + 2) * sizeof (char));
  struct split_result *rptr = (struct split_result *) NULL;
  char *rsptr = (char *) NULL;
  int *rlptr = (int *) NULL;

  if (test == NULL) {
	fprintf (stderr, "Failed to allocate test space in split(): %s\n",
			 strerror (errno));
	return -1;
  }

  if (dlimsiz > strsiz) {
	strcpy (target->str, str);
	target->len = strlen (target->str);

	return 0;
  }

  for (ptr = str, rptr = target, rsptr = rptr->str, rlptr = &rptr->len;
	   *ptr != '\0';
	   ptr++) {
	memcpy (test, ptr, (dlimsiz * sizeof (char)));
	test[dlimsiz] = '\0';
	ptr += (dlimsiz - 1);
	if (strcmp (delim, test) == 0) {
	  /* Finish up this particular result */
	  *rsptr = '\0';
	  *rlptr = strlen (rsptr);

	  /* Move on to the next result */
	  rptr++;
	  rsptr = rptr->str;
	  rlptr = &rptr->len;
	}
	else {
	  *rsptr++ = *ptr;
	}
  }
  *rsptr = '\0';
  *rlptr = strlen (rsptr);

  free (test);

  return 0;
}

struct pud_global_config *get_global_config (struct pud_global_config *target) {
  FILE *infile = (FILE *) NULL;
  char *key = (char *) NULL;
  char *value = (char *) NULL;
  struct split_result keyval[2] = {{"",0},
				   {"",0}};
  char line[BUFSIZ];
  int fline = 0;
  int template_found = 0;
  int version_found = 0;
  int style_found = 0;
  int comment_index_found = 0;

  /* Open the file */
  infile = fopen (PUD_GLOBAL_CONFIG, "r");
  if (infile == NULL) {
    fprintf (stderr, "[%d]Failed to open file '%s' for reading: %s\n",
	     __LINE__, PUD_GLOBAL_CONFIG, strerror (errno));
    return NULL;
  }

  while (fgets (line, (BUFSIZ - 1), infile) != NULL) {
    fline += 1; /* So we can keep track of where we are in the file. Mostly for error reporting. */

    chomp (line);
    if (line[0] != '#' && line[0] != '\0') {
      if (splitstrstr (keyval, line, ":") < 0) {
	fprintf (stderr, "[%d]splitstrstr() failed.  I'm quitting, too!", __LINE__);
	return NULL;
      }
      key = keyval[0].str;
      value = keyval[1].str;

      if (!strcasecmp (key, "template_path")) {
	if (template_found != 0) {
	  fprintf (stderr, "libpud: Multiple values for 'template_path' found in pud.conf file %s.\n",
		   PUD_GLOBAL_CONFIG);
	  return NULL;
	}

	strcpy (target->template_path, value);
	template_found += 1;
      }
      else if (!strcasecmp (key, "version")) {
	if (version_found != 0) {
	  fprintf (stderr, "libpud: Multiple values for 'version' found in pud.conf file %s.\n",
		   PUD_GLOBAL_CONFIG);
	  return NULL;
	}

	strcpy (target->pud_version, value);
	version_found += 1;
      }
      else if (!strcasecmp (key, "style_path")) {
	if (style_found != 0) {
	  fprintf (stderr, "libpud: Multiple values for 'style_path' found in pud.conf file %s.\n",
		   PUD_GLOBAL_CONFIG);
	  return NULL;
	}

	strcpy (target->style_path, value);
	style_found += 1;
      }
      else if (!strcasecmp (key, "comment_index")) {
	if (comment_index_found != 0) {
	  fprintf (stderr, "libpud: Multiple values for 'comment_index' found in pud.conf file %s.\n",
		   PUD_GLOBAL_CONFIG);
	  return NULL;
	}

	strcpy (target->comment_index, value);
	comment_index_found += 1;
      }
      else {
	fprintf (stderr, "libpud: Unknown pud.conf value '%s' at %s line %d.\n",
		 key, PUD_GLOBAL_CONFIG, fline);
      }
    }
  }

  /* Close the file once we're done with it. */
  fclose (infile);

  /* Notify the user if the file is a different version than expected. */
  if (strcmp (target->pud_version, SUPPORTED_PUDRC_VERSION)) {
    fprintf (stderr, "libpud: NOTICE: The version of the pud.conf file '%s' differs from the version that this library is meant to read.  %s is version '%s' while this library is intended to support version '%s'.  Expect strange behavior.\n",
	     PUD_GLOBAL_CONFIG, PUD_GLOBAL_CONFIG, target->pud_version, SUPPORTED_PUDRC_VERSION);
  }

  /* We need all of these values to use PUD. */
  if (template_found != 1) {
    fprintf (stderr, "libpud: Incomplete pud.conf file %s.  Value 'template_path' must be defined.\n",
	     PUD_GLOBAL_CONFIG);
    return NULL;
  }
  else if (version_found != 1) {
    fprintf (stderr, "libpud: Incomplete pud.conf file %s.  Value 'version' must be defined.\n",
	     PUD_GLOBAL_CONFIG);
    return NULL;
  }
  else if (style_found != 1) {
    fprintf (stderr, "libpud: Incomplete pud.conf file %s.  Value 'style_path' must be defined.\n",
	     PUD_GLOBAL_CONFIG);
    return NULL;
  }
  else if (comment_index_found != 1) {
    fprintf (stderr, "libpud: Incomplete pud.conf file %s.  Value 'comment_index' must be defined.\n",
	     PUD_GLOBAL_CONFIG);
    return NULL;
  }

  return target;
}

struct pudrc_data *read_pudrc_file (struct pudrc_data *target, char *file_name, struct pud_global_config conf) {
  char line[BUFSIZ] = "";
  FILE *infile = (FILE *) NULL;
  char *key = (char *) NULL;
  char *value = (char *) NULL;
  int fline = 0;
  struct split_result keyval[2] = {{"",0},
				   {"",0}};
  /* Initialize some values */
  target->copyright_holder[0] = '\0';
  target->pud_version[0] = '\0';
  target->default_template[0] = '\0';
  target->email_address[0] = '\0';

  /* Open the pudrc file */
  infile = fopen (file_name, "r");
  if (infile == NULL && errno != ENOENT) {
    fprintf (stderr, "libpud(%d): Failed to open file '%s' for reading: %s\n",
	     __LINE__, file_name, strerror (errno));
    return NULL;
  }
  else if (errno == ENOENT) {
    if (pud_read_only == TRUE) {
      fprintf (stderr, "libpud(%d): Failed to open file '%s' for reading: %s\n",
	       __LINE__, file_name, strerror (errno));
      return NULL;
    }
    else {
      if (get_pudrc_data_from_user (target, conf, FALSE) == NULL) {
	fprintf (stderr, "libpud(%d): Failed to get pudrc data from user.\n", __LINE__);
	return NULL;
      }
      if (write_pudrc_file (*target, file_name) == FALSE) {
	fprintf (stderr, "libpud(%d): Failed to write pudrc file '%s'.\n", __LINE__, file_name);
	return NULL;
      }
    }
  }
  else {
    /* We only need to read the file into memory if the pudrc file opened without problems */
    while (fgets (line, (BUFSIZ - 1), infile) != NULL) {
      fline += 1;
      chomp (line);
      if (line[0] != '#' && line[0] != '\0') {
	if (splitstrstr (keyval, line, ":") < 0) {
	  fprintf (stderr, "[%d]splitstrstr() failed.  I'm quitting, too!", __LINE__);
	  return NULL;
	}
	key = keyval[0].str;
	value = keyval[1].str;

	if (!strcasecmp (key, "version")) {
	  strcpy (target->pud_version, value);
	}
	else if (!strcasecmp (key, "copyright_holder")) {
	  strcpy (target->copyright_holder, value);
	}
	else if (!strcasecmp (key, "email_address")) {
	  strcpy (target->email_address, value);
	}
	else if (!strcasecmp (key, "default_template")) {
	  strcpy (target->default_template, value);
	}
	else {
	  fprintf (stderr, "libpud: Unknown pudrc value '%s' at %s line %d.\n",
		   key, file_name, fline);
	  return NULL;
	}
      }
    }

    /* Close the file once we're done with it. */
    fclose (infile);
  }

  /* Notify the user if the file is a different version than expected. */
  if (strcmp (target->pud_version, SUPPORTED_PUDRC_VERSION)) {
    fprintf (stderr, "libpud: NOTICE: The version of the pudrc file '%s' differs from the version that this library is meant to read.  %s is version '%s' while this library is intended to support version '%s'.  Expect strange behavior.\n",
	     file_name, file_name, target->pud_version, SUPPORTED_PUDRC_VERSION);
  }

  return target;
}

/* Specialized string concatenation routine.
   Good for catting onto long strings */
char *cat_str (char *dest, char *src) {
  char *ptr = (char *) NULL;
  char *dptr = (char *) NULL;

  for (ptr = src, dptr = dest; *ptr != '\0'; ptr++) {
	*dptr = *ptr;
	dptr++;
  }

  *dptr = '\0';

  return dptr;
}

int strcpy_limit (char *dest, char *src, int limit) {
  char *sptr = (char *) NULL;
  char *dptr = (char *) NULL;
  int count = 0;

  for (sptr = src, dptr = dest;
	   *sptr != '\0' &&
		 count < limit;
	   sptr++, dptr++, count++) {
	*dptr = *sptr;
  }
  *dptr = '\0';

  return count;
}

char *str_replace (char *dest, char *src, char *substr, char *filler) {
  char *dptr = (char *) NULL;
  char *sptr = (char *) NULL;
  char *test = (char *) NULL;

  /* Allocate the test to the size of the substring + 1 (null terminator) */
  test = (char *) malloc ((strlen (substr) + 1) * sizeof (char));
  if (test == NULL) {
	fprintf (stderr, "[%d]Failed to allocate test: %s\n",
			 __LINE__, strerror (errno));
	return NULL;
  }

  for (sptr = src, dptr = dest; *sptr != '\0'; sptr++){
	if (*sptr == *substr) {
	  strcpy_limit (test, sptr, strlen (substr));
	  if (strcmp (test, substr) == 0) {
		sptr += (strlen (substr) - 1);
		dptr = cat_str (dptr, filler);
	  }
	  else {
		*dptr = *sptr;
		dptr++;
	  }
	}
	else {
	  *dptr = *sptr;
	  dptr++;
	}
  }

  free (test);

  *dptr = '\0';

  return dptr;
}

int get_underline_for_string (char *uline, char *str) {
  char *ptr = (char *) NULL;
  int x = 0;

  for (ptr = uline, x = 0; x < (strlen (str) + 1); x++, ptr++) {
	*ptr = '-';
  }
  *ptr = '\0';

  return (strlen (uline) - 1);
}

struct language_info *get_language_info (struct language_info *dest, struct pud_global_config conf, char *lang) {
  FILE *infile = (FILE *) NULL;
  struct split_result fields[4];
  char line[BUFSIZ];
  comment_style_t cstyle = CS_NONE;
  char *fname = (char *) NULL;

  fname = conf.comment_index;

  /* Open the comment index */
  infile = fopen (fname, "r");
  if (infile == NULL) {
	fprintf (stderr, "libpud[%d]: Failed to open comment index file '%s' for reading: %s\n",
			 __LINE__, fname, strerror (errno));
	return NULL;
  }

  /* Read the file */
  while (fgets (line, (BUFSIZ - 1), infile)) {
	chomp (line);
	splitstrstr (fields, line, "~");
	if (strcmp (fields[0].str, lang) == 0) {
	  strcpy (dest->name, fields[0].str);
	  strcpy (dest->comment_multi_open, fields[1].str);
	  strcpy (dest->comment_multi_close, fields[2].str);
	  strcpy (dest->comment_single, fields[3].str);

	  /* Detect the comment style based on the comment types we have defined. */
	  if (dest->comment_single[0] != '\0') {
		cstyle += CS_SINGLE;
	  }
	  if (dest->comment_multi_open[0] != '\0' &&
		  dest->comment_multi_close[0] != '\0') {
		cstyle += CS_MULTI;
	  }
	  dest->comment_style = cstyle;
	}
  }

  fclose (infile);

  return dest;
}

char *parse_template_file (struct pud_template template, char *dest, struct pud_output_info *info) {
  char *fname = (char *) NULL;
  FILE *infile = (FILE *) NULL;
  char *data = (char *) NULL;
  char replacements[BUFSIZ];
  int readin = 0;
  struct stat finfo;
  char *funderline = (char *) NULL;

  fname = template.file_name;

  /* Stat the file */
  if (stat (fname, &finfo) < 0) {
	fprintf (stderr, "libpud[%d]: Failed to stat template file '%s': %s\n",
			 __LINE__, fname, strerror (errno));
	return NULL;
  }

  /* Get the size in bytes contained within the file */
  readin = (int) finfo.st_size;

  /* Allocate the data buffer */
  data = (char *) malloc (readin);
  if (data == NULL) {
	fprintf (stderr, "libpud[%d]: Failed to allocate template file data buffer: %s\n",
			 __LINE__, strerror (errno));
	return NULL;
  }
  /* Allocate the file underline */
  funderline = (char *) malloc ((strlen (info->file_name) + 2) * sizeof (char));
  if (funderline == NULL) {
	fprintf (stderr, "libpud[%d]: Failed to allocate file underline: %s\n",
			 __LINE__, strerror (errno));
	return NULL;
  }

  /* Open the file */
  infile = fopen (fname, "r");
  if (infile == NULL) {
	fprintf (stderr, "libpud[%d]: Failed to open template file '%s' for reading: %s\n",
			 __LINE__, fname, strerror (errno));
	free (data);
	return NULL;
  }

  /* Read the file into the buffer */
  fread (data, sizeof (char), readin, infile);
  if (ferror (infile)) {
	fprintf (stderr, "libpud[%d]: Read error on file '%s'.\n",
			 __LINE__, fname);
	free (data);
	fclose (infile);
	return NULL;
  }
  data[readin] = '\0';

  /* Close file.  We already have the data. */
  fclose (infile);

  /* Do the file underline first */
  get_underline_for_string (funderline, info->file_title);
  str_replace (dest, data, POI_UNDERLINE_FILE_TOKEN, funderline);
  strcpy (replacements, dest);

  /* Replace the tokens */
  str_replace (dest, replacements, POI_FILE_VERSION_TOKEN, info->file_version);
  strcpy (replacements, dest);
  str_replace (dest, replacements, POI_FILE_NAME_TOKEN, info->file_title);
  strcpy (replacements, dest);
  str_replace (dest, replacements, POI_PACKAGE_NAME_TOKEN, info->package_name);
  strcpy (replacements, dest);
  str_replace (dest, replacements, POI_AUTHOR_NAME_TOKEN, info->author_name);
  strcpy (replacements, dest);
  str_replace (dest, replacements, POI_AUTHOR_EMAIL_TOKEN, info->author_email);
  strcpy (replacements, dest);
  str_replace (dest, replacements, POI_YEAR_TOKEN, info->year);

  free (data);
  free (funderline);

  return dest;
}

char *parse_style_file (struct pud_style style,
			char *dest,
			struct pud_output_info *info,
			char *template,
			struct language_info *lang) {
  char *fname = (char *) NULL;
  FILE *infile = (FILE *) NULL;
  char data[BUFSIZ] = "";
  char replacements[BUFSIZ] = "";
  int readin = 0;
  struct stat finfo;
  char *funderline = (char *) NULL;
  char templateData[BUFSIZ] = "";

  fname = style.file_name;

  /* Stat the file */
  if (stat (fname, &finfo) < 0) {
	fprintf (stderr, "libpud[%d]: Failed to stat style file '%s': %s\n",
			 __LINE__, fname, strerror (errno));
	return NULL;
  }

  /* Get the size in bytes contained within the file */
  readin = (int) finfo.st_size;

  /* Using static char array now.  No more need to play with this malloc(). */
/*   /\* Allocate the data buffer *\/ */
/*   data = (char *) malloc (readin); */
/*   if (data == NULL) { */
/* 	fprintf (stderr, "libpud[%d]: Failed to allocate style file data buffer: %s\n", */
/* 			 __LINE__, strerror (errno)); */
/* 	return NULL; */
/*   } */
  /* Allocate the file underline */
  funderline = (char *) malloc ((strlen (info->file_name) + 2) * sizeof (char));
  if (funderline == NULL) {
	fprintf (stderr, "libpud[%d]: Failed to style file underline: %s\n",
			 __LINE__, strerror (errno));
	return NULL;
  }

  /* Commentify the template */
  commentify_data (templateData, template, lang);

  /* Open the file */
  infile = fopen (fname, "r");
  if (infile == NULL) {
	fprintf (stderr, "libpud[%d]: Failed to open style file '%s' for reading: %s\n",
			 __LINE__, fname, strerror (errno));
	return NULL;
  }

  /* Read the file into the buffer */
  fread (data, sizeof (char), readin, infile);
  if (ferror (infile)) {
	fprintf (stderr, "libpud[%d]: Read error on file '%s'.\n",
			 __LINE__, fname);
	fclose (infile);
	return NULL;
  }
  data[readin] = '\0';

  /* Close file.  We already have the data. */
  fclose (infile);

  /* Do the file underline first */
  get_underline_for_string (funderline, info->file_title);
  str_replace (dest, data, POI_UNDERLINE_FILE_TOKEN, funderline);
  strcpy (replacements, dest);

  /* Replace the tokens */
  str_replace (dest, replacements, POI_FILE_VERSION_TOKEN, info->file_version);
  strcpy (replacements, dest);
  str_replace (dest, replacements, POI_FILE_NAME_TOKEN, info->file_title);
  strcpy (replacements, dest);
  str_replace (dest, replacements, POI_PACKAGE_NAME_TOKEN, info->package_name);
  strcpy (replacements, dest);
  str_replace (dest, replacements, POI_AUTHOR_NAME_TOKEN, info->author_name);
  strcpy (replacements, dest);
  str_replace (dest, replacements, POI_AUTHOR_EMAIL_TOKEN, info->author_email);
  strcpy (replacements, dest);
  str_replace (dest, replacements, POI_YEAR_TOKEN, info->year);
  strcpy (replacements, dest);
  str_replace (dest, replacements, POI_TEMPLATE_TOKEN, templateData);

  free (funderline);

  return dest;
}

char *commentify_data (char *dest, char *data, struct language_info *lang) {
  char *pos = (char *) NULL;
  char *tpos = (char *) NULL;
  bool_t now = TRUE;

  switch (lang->comment_style) {
  case CS_NONE:
    return NULL;

  case CS_SINGLE:
    for (pos = data, tpos = dest;
	 *pos != '\0';
	 pos++) {
      if (now == TRUE) {
	tpos = cat_str (tpos, lang->comment_single);
	tpos = cat_str (tpos, " ");
	now = FALSE;
      }
      if (*pos == '\n') {
	now = TRUE;
	*tpos = *pos;
	tpos++;
      }
      else {
	*tpos = *pos;
	tpos++;
      }
    }
    *tpos = '\0';
    break;

  case CS_MULTI:
    tpos = dest;
    pos = data;

    tpos = cat_str (tpos, lang->comment_multi_open);
    tpos = cat_str (tpos, pos);
    tpos = cat_str (tpos, lang->comment_multi_close);
    break;

  case CS_BOTH:
    tpos = dest;
    pos = data;

    tpos = cat_str (tpos, lang->comment_multi_open);
    tpos = cat_str (tpos, pos);
    tpos = cat_str (tpos, lang->comment_multi_close);
    break;

  default:
    return NULL;
  }
  

  return dest;
}

void set_file_title (struct pud_output_info *info) {
  char *fname = (char *) NULL;
  char *ftitle = (char *) NULL;
  char *pos = (char *) NULL;

  for (fname = info->file_name, ftitle = info->file_title, pos = fname;
       *fname != '\0';
       fname++) {
    if (*fname == '/' ||
	*fname == '\\') {
      pos = fname + 1;
    }
  }

  if (*pos != '\0') {
    strcpy (ftitle, pos);
  }

  return;
}

struct pud_template *get_pud_template_data (struct pud_template *target, char *str, struct pud_global_config conf) {
  char expected_file_name[256];
  struct stat stats;
  char *homedir = (char *) NULL;

  homedir = getenv ("HOME");
  if (homedir == NULL) {
    fprintf (stderr, "libpud: Environmental variable '$HOME' must be defined in order to use PUD!\n");
    return NULL;
  }
  sprintf (expected_file_name, "%s/%s.template", homedir, str);
  if (stat (expected_file_name, &stats) < 0) {
    sprintf (expected_file_name, "%s/%s.template", conf.template_path, str);

    if (stat (expected_file_name, &stats) < 0) {
      fprintf (stderr, "libpud: Failed to stat template file '%s': %s\n",
	       expected_file_name, strerror (errno));
      return NULL;
    }
  }

  strcpy (target->rawname, str);
  strcpy (target->file_name, expected_file_name);

  return target;
}

struct pud_style *get_pud_style_data (struct pud_style *target, char *str, struct pud_global_config conf) {
  char expected_file_name[256];
  struct stat stats;
  char *homedir = (char *) NULL;

  homedir = getenv ("HOME");
  if (homedir == NULL) {
    fprintf (stderr, "libpud: Environmental variable '$HOME' must be defined in order to use PUD!\n");
    return NULL;
  }
  sprintf (expected_file_name, "%s/%s.style", homedir, str);
  if (stat (expected_file_name, &stats) < 0) {
    sprintf (expected_file_name, "%s/%s.style", conf.style_path, str);

    if (stat (expected_file_name, &stats) < 0) {
      fprintf (stderr, "libpud: Failed to stat style file '%s': %s\n",
	       expected_file_name, strerror (errno));
      return NULL;
    }
  }

  strcpy (target->rawname, str);
  strcpy (target->file_name, expected_file_name);

  return target;
}

struct pud_output_info *parse_args (struct pud_output_info *target, char *argv[], int argc) {
  int x = 0;
  bool_t isarg = FALSE;
  char *arg = (char *) NULL;
  enum {
	TEMPLATE,
	FILE_VERSION,
	PACKAGE
  } arg_type;
  time_t timeclock;
  struct tm *clock = (struct tm *) NULL;
  int year = 0;
  char yearstr[8] = "";
  char dummy[64] = "";

  /* Let's be nice and initialize the structure for them */
  target->file_version[0] = '\0';
  target->file_title[0] = '\0';
  target->file_name[0] = '\0';
  target->package_name[0] = '\0';
  target->author_name[0] = '\0';
  target->author_email[0] = '\0';
  target->year[0] = '\0';
  target->template_name[0] = '\0';
  target->template.rawname[0] = '\0';
  target->template.file_name[0] = '\0';
  target->whattodo = DOIT_NORMAL;
  /* Initializing helps people tell what we actually got in this function */

  if (argc == 1) {
    target->whattodo = DOIT_HELP;
    return target;
  }

  /* Get the time */
  timeclock = time ((time_t *) NULL);
  clock = localtime (&timeclock);
  year = clock->tm_year + 1900;
  sprintf (yearstr, "%d", year);
  strcpy (target->year, yearstr);

  for (x = 0; x < argc; x++) {
    arg = argv[x];
    if (isarg == TRUE) {
      switch (arg_type) {
      case TEMPLATE:
	strcpy (target->template_name, arg);
	break;
      case FILE_VERSION:
	strcpy (target->file_version, arg);
	break;
      case PACKAGE:
	strcpy (target->package_name, arg);
	break;
      }
      isarg = FALSE;
    }
    else if (strcasecmp (arg, "-h") == 0 ||
	     strcasecmp (arg, "-?") == 0 ||
	     strcasecmp (arg, "--help") == 0) {
      target->whattodo = DOIT_HELP;
    }
    else if (strcasecmp (arg, "-v") == 0 ||
	     strcasecmp (arg, "--version") == 0) {
      target->whattodo = DOIT_VERSION;
    }
    else if (strcasecmp (arg, "-t") == 0 ||
	     strcasecmp (arg, "--template") == 0) {
      arg_type = TEMPLATE;
      isarg = TRUE;
    }
    else if (strcasecmp (arg, "-f") == 0 ||
	     strcasecmp (arg, "--file-version") == 0) {
      arg_type = FILE_VERSION;
      isarg = TRUE;
    }
    else if (strcasecmp (arg, "-p") == 0 ||
	     strcasecmp (arg, "--package") == 0) {
      arg_type = PACKAGE;
      isarg = TRUE;
    }
    else {
      /* This must be the file name if it's not tagged */
      strcpy (target->file_name, arg);
      set_file_title (target);
    }
  }

  if (target->package_name[0] == '\0') {
    strcpy (dummy, target->file_title);
    forceUC (dummy);
    swap_char (dummy, '.', '_');
    strcpy (target->package_name, dummy);
  }

  return target;
}

bool_t check_for_file (struct pud_output_info info) {
  struct stat stats;
  char *fname = (char *) NULL;

  fname = info.file_name;

  if (stat (fname, &stats) < 0) {
    return TRUE;
  }

  printf ("File \"%s\" already exists.  Overwrite? ",
	  fname);
  switch (getc (stdin)) {
  case 'y':
  case 'Y':
    return TRUE;
  default:
    return FALSE;
  }
}

struct pudrc_data *get_pudrc_data_from_user (struct pudrc_data *target,
					     struct pud_global_config conf,
					     bool_t use_defaults) {
  DIR *tpldir = (DIR *) NULL;
  char input[BUFSIZ];
  enum {
    CHOLDER = 0,
    EMAIL = 1,
    TPL = 2,
    DONE = 3
  } itype;
  char tplentry[64] = "";
  struct dirent *dentry = (struct dirent *) NULL;
  int x = 0;

  itype = CHOLDER;

  /* The version is ours to set */
  strcpy (target->pud_version, SUPPORTED_PUDRC_VERSION);

  while (itype < DONE) {
    switch (itype) {
    case CHOLDER:
      printf ("Input the name of the copyright holder: ");
      if (use_defaults == TRUE) {
	printf ("[%s]", target->copyright_holder);
      }
      fgets (input, BUFSIZ, stdin);
      if (input[0] == '\n' && use_defaults == TRUE) {
	itype++;
      }
      else if (strlen (input) > 1) {
	strcpy (target->copyright_holder, input);
	itype++;
      }
      break;
    case EMAIL:
      printf ("Input your email address: ");
      if (use_defaults == TRUE) {
	printf ("[%s]", target->email_address);
      }
      fgets (input, BUFSIZ, stdin);
      if (input[0] == '\n' && use_defaults == TRUE) {
	itype++;
      }
      else if (strlen (input) > 1) {
	strcpy (target->email_address, input);
	itype++;
      }
      break;
    case TPL:
      printf ("Choose a default template (enter '?' for a list): ");
      if (use_defaults == TRUE) {
	printf ("[%s]", target->default_template);
      }
      fgets (input, BUFSIZ, stdin);
      if (input[0] == '\n' && use_defaults == TRUE) {
	itype++;
      }
      else if (input[0] == '?') {
	/* List all templates */
	tpldir = opendir (conf.template_path);
	if (tpldir == NULL) {
	  fprintf (stderr, "libpud: Failed to open template directory '%s' for reading: %s\n",
		   conf.template_path, strerror (errno));
	  return NULL;
	}

	do {
	  dentry = readdir (tpldir);
	  if (dentry != NULL) {
	    chomp (dentry->d_name);
	    chomp (dentry->d_name);
	    if (strstr ((const char *) dentry->d_name, ".template") != NULL) {
	      strcpy (tplentry, dentry->d_name);
	      truncate_string_at_char (tplentry, '.');
	      printf ("%s ", tplentry);
	      if (x % 3 == 0 && x > 0) {
		printf ("\n");
	      }
	      x += 1;
	    }
	  }
	} while (dentry != NULL);
	if (x % 3 != 0) {
	  printf ("\n");
	}
      }
      else if (strlen (input) > 1) {
	strcpy (target->default_template, input);
	itype++;
      }
      break;
    case DONE:
      break;
    }
  }

  chomp (target->default_template);
  chomp (target->copyright_holder);
  chomp (target->email_address);

  return target;
}

char *truncate_string_at_char (char *str, char chr) {
  char *ptr = (char *) NULL;

  for (ptr = str; *ptr != '\0'; ptr++) {
    if (*ptr == chr) {
      *ptr = '\0';
    }
  }

  return str;
}

bool_t write_pudrc_file (struct pudrc_data data, char *fname) {
  FILE *outfile = (FILE *) NULL;

  outfile = fopen (fname, "w");
  if (outfile == NULL) {
    fprintf (stderr, "libpud: Failed to open pudrc file '%s' for writing: %s\n",
	     fname, strerror (errno));
    return FALSE;
  }

  fprintf (outfile, "version:%s\ncopyright_holder:%s\nemail_address:%s\ndefault_template:%s\n",
	   data.pud_version,
	   data.copyright_holder,
	   data.email_address,
	   data.default_template);

  fclose (outfile);

  return TRUE;
}

char *forceUC (char *str) {
  char *ptr = (char *) NULL;

  for (ptr = str; *ptr != '\0'; ptr++) {
    *ptr = toupper (*ptr);
  }

  return str;
}

char *forceLC (char *str) {
  char *ptr = (char *) NULL;

  for (ptr = str; *ptr != '\0'; ptr++) {
    *ptr = tolower (*ptr);
  }

  return str;
}

char *swap_char (char *str, char replace, char with) {
  char *ptr = (char *) NULL;

  for (ptr = str; *ptr != '\0'; ptr++) {
    if (*ptr == replace) {
      *ptr = with;
    }
  }

  return str;
}

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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <sys/stat.h>
#include <unistd.h>

#include "libpud.h"

extern int errno;

void doHelp (void);
void doVersion (void);

int main (int argc, char *argv[])
{
  struct pud_output_info output;
  struct language_info lang;
  struct pudrc_data pudrc;
  struct pud_global_config global;
  char *homedir = (char *) NULL;
  char pudrc_file[128];
  char after_template[BUFSIZ];
  char real_output[BUFSIZ];
  FILE *outfile = (FILE *) NULL;

  parse_args (&output, argv, argc);
  if (output.whattodo == DOIT_HELP) {
    doHelp ();
    exit (EXIT_SUCCESS);
  }
  else if (output.whattodo == DOIT_VERSION) {
    doVersion ();
    exit (EXIT_SUCCESS);
  }

  /* Load the global configs */
  if (get_global_config (&global) == NULL) {
    fprintf (stderr, "libpud: Failed to obtain the PUD global configuration file '%s'!\n",
	     PUD_GLOBAL_CONFIG);
    exit (EXIT_FAILURE);
  }

  /* Get the $HOME value */
  homedir = getenv ("HOME");
  if (homedir == NULL) {
    fprintf (stderr, "newc: Environmental variable '$HOME' must be set in order to run PUD.\n");
    exit (EXIT_FAILURE);
  }

  /* Read the pudrc file */
  sprintf (pudrc_file, "%s/.pudrc", homedir);
  if (read_pudrc_file (&pudrc, pudrc_file, global) == NULL) {
    exit (EXIT_FAILURE);
  }

  /* Copy the data from the pudrc into the output */
  strcpy (output.author_name, pudrc.copyright_holder);
  strcpy (output.author_email, pudrc.email_address);
  if (output.package_name[0] == '\0' &&
      output.file_title[0] != '\0') {
    strcpy (output.package_name, output.file_title);
  }

  /* If no template is specified, use the default template */
  if (output.template_name[0] == '\0') {
    strcpy (output.template_name, pudrc.default_template);
  }

  /* Load the data for the template */
  if (get_pud_template_data (&output.template, output.template_name, global) == NULL) {
    exit (EXIT_FAILURE);
  }

  /* Load the data for the style */
  if (get_pud_style_data (&output.style, "c", global) == NULL) {
    exit (EXIT_FAILURE);
  }

  /* Load the language information */
  if (get_language_info (&lang, global, "c") == NULL) {
    exit (EXIT_FAILURE);
  }

  /* Parse the template */
  if (parse_template_file (output.template, after_template, &output) == NULL) {
    fprintf (stderr, "newc: Failed to parse template file '%s'!\n",
	     output.template.file_name);
    exit (EXIT_FAILURE);
  }

  /* Parse the style */
  if (parse_style_file (output.style, real_output, &output, after_template, &lang) == NULL) {
    fprintf (stderr, "newc: Failed to parse style file '%s'!\n",
	     output.style.file_name);
    exit (EXIT_FAILURE);
  }

  /* Does the file exist? */
  if (check_for_file (output) == FALSE) {
    printf ("newc: Aborting.\n");
    exit (EXIT_SUCCESS);
  }

  /* Open the output file */
  outfile = fopen (output.file_name, "w");
  if (outfile == NULL) {
    fprintf (stderr, "newc: Failed to open file '%s' for writing: %s\n",
	     output.file_name, strerror (errno));
    exit (EXIT_FAILURE);
  }

  /* Write the output */
  fwrite (real_output, sizeof (char), strlen (real_output), outfile);

  /* Close the output file */
  fclose (outfile);

  exit (EXIT_SUCCESS);
}

void doHelp (void) {
  /* FIXME */
  printf ("Usage: newc [FILE] [OPTIONS]\n");
  printf (" OPTIONS LIST\n");
  printf ("  --help|-h|-?                  Display This help message\n");
  printf ("  --version|-v                  Display version information\n");
  printf ("  --template|-t     TEMPLATE    Set the template to use\n");
  printf ("  --file-version|-f VERSION     Set the version for the output file\n");
  printf ("  --package|-p      PACKAGE     Set the package name for the output file\n");

  return;
}

void doVersion (void) {
  /* FIXME */
  printf ("PUD is Copyright(C)2000-2002 Michael D. Stemle, Jr.; NotSoSoft; Gnurds Nurds\n");
  printf ("This is PUD version '%s'.\n", PUD_PROG_VERSION);

  return;
}

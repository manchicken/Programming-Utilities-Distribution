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
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/

#ifndef _GNU_SOURCE
# define _GNU_SOURCE 1
#endif //_GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <ctype.h>

#include "libpud.h"

extern int errno;
/* For read-only functionality in read/get functions */
extern bool_t pud_read_only;

int main (int argv, char *argc[])
{
  struct pud_global_config global;
  struct pudrc_data pudrc;
  char *homedir = (char *) NULL;
  char pudrc_file_name[FILENAME_MAX] = "";
  char response = '\0';
  bool_t use_defaults = TRUE;
  char rstr[BUFSIZ];

  /* Make sure that libpud read/get functions only read and don't generate new stuff */
  pud_read_only = TRUE;

  /* Confirm that the user wishes to overwrite their pudrc file. */
  printf ("Are you certain that you wish to regenerate your pudrc file? [y|n]: ");
  fgets (rstr, BUFSIZ, stdin);
  response = rstr[0];
  if (response != 'y' &&
      response != 'Y') {
    printf ("Exiting pudconf...\n");
    exit (EXIT_SUCCESS);
  }

  /* Get the filename for the pudrc file */
  homedir = getenv ("HOME");
  if (homedir == NULL) {
    fprintf (stderr, "pudconf: Environmental variable '$HOME' must be set in order to use PUD.\n");
    exit (EXIT_FAILURE);
  }
  sprintf (pudrc_file_name, "%s/.pudrc", homedir);

  /* Grab a copy of the existing configs... */
  if (read_pudrc_file (&pudrc, pudrc_file_name, global) == NULL) {
    use_defaults = FALSE;
  }

  /* Grab the data from the user */
  if (get_global_config (&global) == NULL) {
    fprintf (stderr, "pudconf: Failed to load global PUD configs.  Exiting...\n");
    exit (EXIT_FAILURE);
  }
  if (get_pudrc_data_from_user (&pudrc, global, use_defaults) == NULL) {
    fprintf (stderr, "pudconf: Failed to get pudrc data from the user (you).  Exiting...\n");
    exit (EXIT_FAILURE);
  }
  /* Write a new pudrc file */
  if (write_pudrc_file (pudrc, pudrc_file_name) == FALSE) {
    fprintf (stderr, "pudconf: Failed to write pudrc file '%s'.  Exiting...\n",
	     pudrc_file_name);
    exit (EXIT_FAILURE);
  }

  exit (EXIT_SUCCESS);
}

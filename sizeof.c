/*Copyright(C)2002 - Michael D. Stemle, Jr. (mstemle@digitalwork.com)
 
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

extern int strcasecmp (const char *a, const char *b);
extern char *strstr (const char *s1, const char *s2);

void doHelp (void);

int main (int argv, char *argc[]) {
  int size = 0;
  char *type = (char *) NULL;
  char isType = 'n';

  if (argv > 1) {
	type = argc[1];
  }
  else {
	doHelp ();

	return 0;
  }

  if (!strcasecmp (type, "long")) {
	size = sizeof (long);
	isType = 'y';
  }
  else if (!strcasecmp (type, "short")) {
	size = sizeof (short);
	isType = 'y';
  }
  else if (!strcasecmp (type, "int")) {
	size = sizeof (int);
	isType = 'y';
  }
  else if (!strcasecmp (type, "char")) {
	size = sizeof (char);
	isType = 'y';
  }
  else if (!strcasecmp (type, "float")) {
	size = sizeof (float);
	isType = 'y';
  }
  else if (!strcasecmp (type, "double")) {
	size = sizeof (double);
	isType = 'y';
  }
  else if (!strcasecmp (type, "BUFSIZ")) {
	size = 0;
	isType = 'b';
  }
  else if (strstr (type, "help")) {
	doHelp ();

	return 0;
  }
  else {
	size = strlen (type) * sizeof (char);
	isType = 'n';
  }

  switch (isType) {
  case 'y':
	printf ("Data type %s is %d bytes long.\n", type, size);
	break;
  case 'b':
	printf ("BUFSIZ is %d bytes.\n", BUFSIZ);
	break;
  default:
	printf ("String \"%s\" is %d bytes long.\n", type, size);
	break;
  };

  return 0;
}

void doHelp (void) {
  printf ("Usage: sizeof [type|STRING|option]\n");
  printf ("   Types:\n");
  printf ("      short, int, long\n");
  printf ("      float, double\n");
  printf ("      char\n");
  printf ("   Options:\n");
  printf ("      help\n");
  printf ("\n   Passing a string to sizeof prints the size of the string in bytes.\n");

  return;
}

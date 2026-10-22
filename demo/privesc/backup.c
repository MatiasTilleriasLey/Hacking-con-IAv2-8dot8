/* SUID root backup helper - VULNERABLE BY DESIGN.
 * Calls `tar` WITHOUT an absolute path, so $PATH is attacker-controlled.
 * www-data can drop a malicious `tar` earlier in PATH and get a root shell.
 */
#include <stdlib.h>
#include <unistd.h>

int main(void) {
    setuid(0);
    setgid(0);
    /* relative command name -> PATH hijack */
    system("tar -czf /tmp/www-backup.tar.gz /var/www/html");
    return 0;
}

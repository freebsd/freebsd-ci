import javax.mail.*
import javax.mail.internet.*

Address[] jenkinsAdmin = [
    'jenkins-admin@FreeBSD.org',
].collect { new InternetAddress(it) }

patterns = [
    'hudson.remoting.ChannelClosedException',
    'hudson.remoting.RequestAbortedException:',
    'org.tmatesoft.svn.core.SVNException',
    'Connection aborted: org.jenkinsci.remoting',
    'Connection was broken: java.io.IOException',
    'Failed to connect to proxy',
    'Test reports were found but none of them are new.',
    'No space left on device',
    'tar: Error opening archive: Failed to open',
    'Build timed out',
    'fetch: INDEX.bz2 appears to be truncated',
    'unable to access \'https://github.com/freebsd/freebsd-ci',
    'fetch-pack: unexpected disconnect while reading sideband packet'
]

try {
    logger.write('Checking with false-positive patterns...\n')
    def logFilePath = build.getLogFile().getPath();
    String logContent = new File(logFilePath).text;
    patterns.find {
        if (logContent.find(/$it/)) {
            logger.write('******** This is Jenkins internal issue! ********\n')
            msg.setRecipients(Message.RecipientType.TO, jenkinsAdmin)
            return true
        }
        return false
    }
} catch (all) {
        logger.write('******** Pre-send script got exception! ********\n')
        msg.setRecipients(Message.RecipientType.TO, jenkinsAdmin)
}

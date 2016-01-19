/*
 * Copyright (c) 2016, Craig Rodrigues <rodrigc@FreeBSD.org>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice unmodified, this list of conditions, and the following
 *    disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *     documentation and|or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

// This script uses the Jenkins workflow plugin.
// It does the following:
//    1. Builds the FreeBSD doc tree.

//
// Build parameters which must be configured in the job
// and then passed down to this script as variables:
//
//    BUILD_NODE
//    CLEAN
//    FREEBSD_DOC_URL
//    VIEW_SVN
//    EMAIL_TO
//    SCRIPT_URL

String doc_url = 'svn://svnmir.freebsd.org/base/head'
String workspace
String email_to
boolean clean = false

if (getBinding().hasVariable("CLEAN")) {
    clean = CLEAN.toBoolean()
}

if (getBinding().hasVariable("FREEBSD_DOC_URL")) {
    doc_url = FREEBSD_DOC_URL
}

if (getBinding().hasVariable("EMAIL_TO")) {
    email_to = EMAIL_TO
}


/*
 * Allocate a node to perform build steps on.
 * The name of the node is configured in the BUILD_NODE
 * parameter in the job.
 *
 */
node(BUILD_NODE) {
try {
    workspace = pwd()
    String script_root = "${workspace}/freebsd-ci"

    if (getBinding().hasVariable("VIEW_SVN")) {
        view_svn = VIEW_SVN.toURL()
    }

    String makeobjdirprefix = "${workspace}/obj"

    if (clean) {
        // If the CLEAN build parameter is set in the job,
        // then remove all the files in the workspace and exit
        sh "sudo chown -R jenkins ."
        return deleteDir()
    }

    dir('doc') {
        stage 'Checkout doc'
        // Check out the doc tree
        checkout([$class: 'SubversionSCM',
                  additionalCredentials: [],
                  browser: [$class: 'ViewSVN', url: view_svn],
                  excludedCommitMessages: '',
                  excludedRegions: '',
                  excludedRevprop: '',
                  excludedUsers: '',
                  filterChangelog: false,
                  ignoreDirPropChanges: false,
                  includedRegions: '',
                  locations: [[credentialsId: '',
                               depthOption: 'infinity',
                               ignoreExternalsOption: false,
                               local: '.',
                               remote: "${doc_url}"]],
                               workspaceUpdater: [$class: 'UpdateUpdater']
                              ])


        withEnv(["WORKSPACE=${workspace}",
                 "MAKEOBJDIRPREFIX=${makeobjdirprefix}",
                 "BUILD_ROOT=" + pwd() ]) {

           // Build the doc tree
           stage "Build"
           sh "make all"
        }
       // Wait a bit before calling the Warnings plugin
       // so that all console output is available.
       sleep 3L

       // Use the Warnings plugin to analyze for compiler warnigs
       step([$class: 'WarningsPublisher',
          canComputeNew: false,
          canResolveRelativePaths: false,
          consoleParsers: [[parserName: 'Clang (LLVM based)']],
          defaultEncoding: '',
          excludePattern: '',
          healthy: '',
          includePattern: '',
          messagesPattern: '',
          unHealthy: ''])
    }
} finally {
        // Send e-mail notifications for failed or unstable builds
        step([$class: 'Mailer',
           notifyEveryUnstableBuild: true,
           recipients: "${email_to}",
           sendToIndividuals: true])

}
}

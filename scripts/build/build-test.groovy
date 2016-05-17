/*
 * Copyright (c) 2015, Craig Rodrigues <rodrigc@FreeBSD.org>
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
//    1. Builds the FreeBSD src tree.
//    2. Creates a VM disk image which can boot in bhyve.
//    3. Boots the VM disk image in bhyve
//    4. Runs the FreeBSD test suite in the VM

//
// Build parameters which must be configured in the job
// and then passed down to this script as variables:
//
//    BUILD_NODE
//    CLEAN
//    FREEBSD_SRC_URL
//    VIEW_SVN
//    EMAIL_TO
//    MAKE_CONF_FILE
//    SCRIPT_URL
//    SKIP_BUILD_UFS_IMAGE
//    SKIP_TEST
//    TEST_NODE
//    TEST_CONFIG_FILE

import groovy.json.JsonSlurperClassic
import groovy.json.JsonBuilder
import java.net.URL

String src_url = 'svn://svnmir.freebsd.org/base/head'
String script_url = 'https://github.com/freebsd/freebsd-ci.git'
String make_conf_file = MAKE_CONF_FILE
String workspace
String json_str
String email_to
String test_node = ''
boolean skip_test = false
boolean skip_build_ufs_image = false

if (getBinding().hasVariable("FREEBSD_SRC_URL")) {
    src_url = FREEBSD_SRC_URL
}

if (getBinding().hasVariable("SCRIPT_URL")) {
    script_url = SCRIPT_URL
}

if (getBinding().hasVariable("EMAIL_TO")) {
    email_to = EMAIL_TO
}

if (getBinding().hasVariable("TEST_NODE")) {
    test_node = TEST_NODE
} else {
    test_node = BUILD_NODE
}

if (getBinding().hasVariable("SKIP_TEST")) {
    skip_test = SKIP_TEST.toBoolean()
}

if (getBinding().hasVariable("SKIP_BUILD_UFS_IMAGE")) {
    skip_build_ufs_image = SKIP_BUILD_UFS_IMAGE.toBoolean()
}

def err = null
currentBuild.result = "SUCCESS"

try {
/*
 * Allocate a node to perform build steps on.
 * The name of the node is configured in the BUILD_NODE
 * parameter in the job.
 *
 */
node(BUILD_NODE) {
    workspace = pwd()
    String script_root = "${workspace}/freebsd-ci"
    String build_script = "${script_root}/scripts/build/build1.sh"
    String build_ufs_script = "${script_root}/scripts/build/build-ufs-image.sh"
    java.net.URL view_svn = new java.net.URL("http://svnweb.freebsd.org/base/")

    if (getBinding().hasVariable("VIEW_SVN")) {
        view_svn = VIEW_SVN.toURL()
    }

    String makeobjdirprefix = "${workspace}/obj"

    if ("${CLEAN}" == "true") {
        // If the CLEAN build parameter is set in the job,
        // then remove all the files in the workspace and exit
        sh "sudo chown -R jenkins ."
        return deleteDir()
    }

    stage 'Checkout scripts'
    dir ("freebsd-ci") {
        git changelog: false, poll: false, url: "${script_url}"
    }

    dir('src') {
        stage 'Checkout src'
        // Check out the source tree
        //svn "${src_url}"
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
                               remote: "${src_url}"]],
                               workspaceUpdater: [$class: 'UpdateUpdater']
                              ])


        withEnv(["WORKSPACE=${workspace}",
                 "MAKEOBJDIRPREFIX=${makeobjdirprefix}",
                 "BUILD_ROOT=" + pwd(),
                 "MAKE_CONF_FILE=${make_conf_file}",
                 "CONFIG_JSON=" + TEST_CONFIG_FILE ]) {

           // Build the source tree
           stage "Build"
           sh "${build_script}"

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

           if (!skip_build_ufs_image) {
               // Build a UFS image which can be booted in bhyve
               stage "Build UFS image"
               sh "${build_ufs_script}"
           }
        }

    }

    // Parse the template json config file
    def conf = readFile("${TEST_CONFIG_FILE}")
    def slurper = new JsonSlurperClassic()
    json_data = slurper.parseText(conf)

    // Write out location of disk image in new json config file,
    // prefixed with /net so that we can access it via NFS.
    json_data['disks'][0] = '/net/' + BUILD_NODE + "/${workspace}/image/src/test.img"
    def builder = new JsonBuilder(json_data)
    json_str = builder.toPrettyString()
}

/*
 * Allocate a node to perform test steps on.
 * The name of the node is configured in the TEST_NODE
 * parameter in the job.
 *
 */
!skip_build_ufs_image && !skip_test && 
    node("${test_node}") {
        dir ("freebsd-ci") {
            git changelog: false, url: "${script_url}"
        }
    
        // Write out the new json config file, to be used by subsequent scripts
        writeFile file: 'config.json', text: json_str
    
        stage "Test"
        /*
         * Boot the UFS image in a bhyve VM.
         * Run the tests in the VM.
         * Shut down the VM.
         */
        sh 'sudo python freebsd-ci/scripts/test/run-tests.py -f config.json'
    
        /*
         * Mount the UFS image, and extract the JUnit test-report.xml
         * file.
         */
        sh 'sudo python freebsd-ci/scripts/test/extract-test-logs.py -f config.json'
    
        /*
         * Use the JUnit plugin to analyze the test-report.xml test results
         */
        step([$class: 'JUnitResultArchiver', testResults: 'test-report.xml'])
    }
} catch (caughtError) {
    err = caughtError
    currentBuild.result = "FAILURE"
} finally {
    (currentBuild.result != "ABORTED") && node("master") {
        // Send e-mail notifications for failed or unstable builds.
        // currentBuild.result must be non-null for this step to work.
        step([$class: 'Mailer',
           notifyEveryUnstableBuild: true,
           recipients: "${email_to}",
           sendToIndividuals: true])
    }

    /* Must re-throw exception to propagate error */
    if (err) {
        throw err
    }
}

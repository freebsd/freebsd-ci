#!/usr/local/bin/groovy

@Grab(group='org.codehaus.groovy.modules.http-builder', module='http-builder', version='0.7.2')
import groovyx.net.http.HTTPBuilder
import static groovyx.net.http.ContentType.JSON
import static groovyx.net.http.Method.POST

if (build.result == hudson.model.Result.SUCCESS) {
  try {

    job_name = build.envVars.JOB_NAME
    revision = build.envVars.SVN_REVISION as Integer
    branch = build.envVars.FBSD_BRANCH
    target = build.envVars.FBSD_TARGET
    target_arch = build.envVars.FBSD_TARGET_ARCH
    build_type = build.envVars.LINK_TYPE

    json_req = sprintf("{\"job_name\":\"%s\",\"revision\":%d,\"branch\":\"%s\",\"target\":\"%s\",\"target_arch\":\"%s\",\"build_type\":\"%s\"}",
                    job_name, revision, branch, target, target_arch, build_type)
    
    def http = new HTTPBuilder('https://artifact.ci.freebsd.org:8182')
    http.auth.basic(build.envVars.ARTIFACT_CRED_USER, build.envVars.ARTIFACT_CRED_PASS)
    response = http.request(POST, JSON) {
      uri.path = '/'
      body = json_req
      response.success = { resp, reader ->
        println reader
      }
    }
  } catch (Exception e) {
    println "Got Exception: " + e.getMessage()
  }
}

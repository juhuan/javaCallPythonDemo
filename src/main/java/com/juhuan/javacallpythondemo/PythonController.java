package com.juhuan.javacallpythondemo;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;

/**
 * @author juhuan.wy
 * @version PythonController.java, v 0.1 2022年10月12日 11:45 juhuan.wy
 */
@RestController
public class PythonController {

    @Value("${scripts.root.path}")
    private String scriptsRootPath;

    @RequestMapping("/callPython")
    public String callPython() throws IOException {

        try {
            String         pythonFilePath = scriptsRootPath + "script.py";
            String         pythonParam    = "aaa";
            Process        proc           = Runtime.getRuntime().exec(String.format("python %s %s", pythonFilePath, pythonParam));
            BufferedReader in             = new BufferedReader(new InputStreamReader(proc.getInputStream()));

            String result = "";
            String line   = null;
            while ((line = in.readLine()) != null) {
                result = result + line + "\n";
            }
            in.close();
            proc.waitFor();
            return result;
        } catch (Exception e) {
            e.printStackTrace();
            return e.getLocalizedMessage();
        }
    }
}
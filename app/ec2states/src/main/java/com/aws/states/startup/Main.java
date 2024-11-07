import org.apache.catalina.Context;
import org.apache.catalina.startup.Tomcat;

import java.io.File;

public class Main {

    public static void main(String[] args) throws Exception {
        // Crear instancia de Tomcat embebido
        Tomcat tomcat = new Tomcat();
        tomcat.setPort(8080);

        // Configurar el contexto para la aplicación web
        Context context = tomcat.addWebapp("", new File("src/main/webapp").getAbsolutePath());

        // Configurar FacesServlet para manejar archivos .xhtml
        Tomcat.addServlet(context, "FacesServlet", "jakarta.faces.webapp.FacesServlet");
        context.addServletMappingDecoded("*.xhtml", "FacesServlet");

        // Iniciar Tomcat
        tomcat.start();
        tomcat.getServer().await();
    }
}

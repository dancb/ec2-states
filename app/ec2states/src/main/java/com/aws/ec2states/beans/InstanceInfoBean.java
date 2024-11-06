package com.aws.ec2states.beans;

import jakarta.annotation.PostConstruct;
import jakarta.faces.view.ViewScoped;
import jakarta.inject.Named;

import javax.json.Json;
import javax.json.JsonArray;
import javax.json.JsonObject;
import javax.json.JsonReader;
import javax.json.JsonWriter;
import java.io.*;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

@Named
@ViewScoped
public class InstanceInfoBean implements Serializable {

    private List<InstanceInfo> instances;
    private static final String LAMBDA_URL = "https://2xp26vbwagvh4l4eyyz3ehg2c40ybxsd.lambda-url.us-east-1.on.aws/";

    @PostConstruct
    public void init() {
        instances = new ArrayList<>();

        try {
            // Configura la conexión para una solicitud POST
            URL url = new URL(LAMBDA_URL);
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setRequestMethod("POST");
            connection.setRequestProperty("Content-Type", "application/json");
            connection.setDoOutput(true);

            // Crea el JSON de los parámetros
            JsonObject requestJson = Json.createObjectBuilder()
                    .add("region", "us-east-1")
                    .add("account_ids", Json.createArrayBuilder().add("303057168699"))
                    .build();

            // Envía el JSON en el cuerpo de la solicitud
            try (OutputStream os = connection.getOutputStream();
                 JsonWriter writer = Json.createWriter(os)) {
                writer.writeObject(requestJson);
                os.flush();
            }

            // Lee la respuesta del Lambda
            StringBuilder content = new StringBuilder();
            try (BufferedReader in = new BufferedReader(new InputStreamReader(connection.getInputStream()))) {
                String inputLine;
                while ((inputLine = in.readLine()) != null) {
                    content.append(inputLine);
                }
            }
            connection.disconnect();

            // Procesa la respuesta JSON
            try (JsonReader jsonReader = Json.createReader(new StringReader(content.toString()))) {
                JsonObject rootNode = jsonReader.readObject();
                JsonObject bodyNode = rootNode.getJsonObject("body");

                if (bodyNode == null) {
                    System.out.println("La clave 'body' no está presente en la respuesta.");
                    return;
                }

                JsonArray bodyContent = bodyNode.getJsonArray("instances");
                for (JsonObject instanceNode : bodyContent.getValuesAs(JsonObject.class)) {
                    String instanceId = instanceNode.getString("InstanceId", "");
                    String state = instanceNode.getString("State", "");

                    List<Tag> tags = new ArrayList<>();
                    JsonArray tagsArray = instanceNode.getJsonArray("Tags");
                    if (tagsArray != null) {
                        for (JsonObject tagNode : tagsArray.getValuesAs(JsonObject.class)) {
                            String key = tagNode.getString("Key", "");
                            String value = tagNode.getString("Value", "");
                            tags.add(new Tag(key, value));
                        }
                    }

                    instances.add(new InstanceInfo(instanceId, state, tags));
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public List<InstanceInfo> getInstances() {
        return instances;
    }

    public static class InstanceInfo {
        private String instanceId;
        private String state;
        private List<Tag> tags;

        public InstanceInfo(String instanceId, String state, List<Tag> tags) {
            this.instanceId = instanceId;
            this.state = state;
            this.tags = tags;
        }

        public String getInstanceId() {
            return instanceId;
        }

        public String getState() {
            return state;
        }

        public List<Tag> getTags() {
            return tags;
        }
    }

    public static class Tag {
        private String key;
        private String value;

        public Tag(String key, String value) {
            this.key = key;
            this.value = value;
        }

        public String getKey() {
            return key;
        }

        public String getValue() {
            return value;
        }
    }
}

# Imagem da API para o runtime de containers da Vercel (ou qualquer Docker).
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
COPY src src
RUN mvn -q -B package -DskipTests

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
COPY docker-entrypoint.sh .
ENTRYPOINT ["sh", "/app/docker-entrypoint.sh"]

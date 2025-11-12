# Multi-stage Dockerfile for applications/app-service
# Builder: uses Gradle (with JDK 21) to produce the Spring Boot fat JAR
# Runtime: lightweight Eclipse Temurin JRE 21

FROM gradle:8.6-jdk21 AS builder
WORKDIR /home/gradle/project

# Copy the whole project and build the module's bootJar (skip tests for speed)
# Use the Gradle wrapper present in the repo for reproducible builds
COPY --chown=gradle:gradle . .
# Build the application using the container-provided gradle (wrapper may not be executable on Windows)
RUN gradle :app-service:bootJar -x test --no-daemon

# Collect the built jar into a known path
RUN mkdir -p /build-output \
 && cp applications/app-service/build/libs/*.jar /build-output/app.jar

FROM eclipse-temurin:21-jre-jammy AS runtime
LABEL maintainer="team"
# JVM tuned for low-memory (1GB) servers: small heap and limit processors
ENV JAVA_OPTS="-Xms128m -Xmx512m -XX:ActiveProcessorCount=1 -XX:+UseContainerSupport -Djava.security.egd=file:/dev/./urandom"
EXPOSE 8081
VOLUME /tmp

COPY --from=builder /build-output/app.jar /app/app.jar

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]

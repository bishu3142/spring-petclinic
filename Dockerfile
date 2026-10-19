FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /build

COPY ./src ./src
COPY ./pom.xml .
COPY ./mvnw .
COPY ./.mvn ./.mvn

RUN ./mvnw dependency:go-offline -DskipTests

RUN ./mvnw package -DskipTests

FROM eclipse-temurin:21-jre-alpine

RUN addgroup -S appuser && adduser -S appuser -G appuser

USER appuser

WORKDIR /app

COPY --from=builder /build/target/*.jar ./app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]

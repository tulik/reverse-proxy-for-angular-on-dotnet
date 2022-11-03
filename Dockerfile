#See https://aka.ms/containerfastmode to understand how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

# Fix for the currency symbol

FROM mcr.microsoft.com/dotnet/sdk:6.0-bullseye-slim AS build
ARG ASPNETCORE_ENVIRONMENT=Production
ENV ASPNETCORE_ENVIRONMENT $ASPNETCORE_ENVIRONMENT
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false
ENV LC_ALL=en_US.UTF-8  \
    LANG=en_US.UTF-8

# install NodeJS 14.x
# see https://github.com/nodesource/distributions/blob/master/README.md#deb
RUN apt-get update -yq
RUN apt-get install curl gnupg -yq
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get install -y nodejs
WORKDIR /app
COPY ["./my-new-app.csproj", "./"]
RUN dotnet restore "my-new-app.csproj"
COPY . /app
RUN dotnet build "my-new-app.csproj" -c Release -o /app/build

FROM build AS publish
ARG ASPNETCORE_ENVIRONMENT=Production
ENV ASPNETCORE_ENVIRONMENT $ASPNETCORE_ENVIRONMENT
ENV CERT_PASSWORD=123
WORKDIR /app
RUN dotnet dev-certs https -ep /app/publish/aspnetapp.pfx -p ${CERT_PASSWORD}
#publish will perform the 'ng build'
RUN dotnet publish "my-new-app.csproj" -c Release -o /app/published

FROM base AS final
ARG ASPNETCORE_ENVIRONMENT=Production
ENV ASPNETCORE_ENVIRONMENT $ASPNETCORE_ENVIRONMENT
WORKDIR /app
COPY --from=publish /app/published .
EXPOSE 80
ENTRYPOINT ["dotnet", "my-new-app.dll"]
ENV ASPNETCORE_URLS http://+:5000
EXPOSE 5000

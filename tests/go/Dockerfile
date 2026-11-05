FROM golang:1.26 AS build
WORKDIR /src
COPY go.mod ./
COPY *.go ./
RUN CGO_ENABLED=0 go build -o /fixture .

FROM scratch
COPY --from=build /fixture /fixture
ENTRYPOINT ["/fixture"]

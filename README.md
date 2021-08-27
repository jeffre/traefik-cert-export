# traefik-cert-export

Export TLS certs from traefik's acme.json file

```
$ ./traefik-cert-export.sh -h
  PURPOSE:
    Export TLS certs from traefik acme.json file.

  USAGE:
    traefik-cert-export.sh [OPTIONS] [DOMAIN, ...]
  
    If no DOMAINs are specified all domains will be exported.

  OPTIONS:
    -i JSONFILE
      json file to read from (default: "./acme.json")
    -c CERTRESOLVER
      Name of the certificate resolver per traefik's configuration (default: "letsencrypt")
    -o OUTPUTDIR
      directory to put cer and key files (default: "./certs")
    -l
      list available domains and then exit
    -v
      increase verbosity
    -h
      print this usage guide
```
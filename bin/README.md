# Manual

* start-proxy: `. start-proxy [1081] [scheme] [host]`
    * for example `. start-proxy 1081 socks5h 127.0.0.1` will set these environment variables:
    ```shell
    http_proxy=socks5h://127.0.0.1:1081
    https_proxy=socks5h://127.0.0.1:1081
    ftp_proxy=socks5h://127.0.0.1:1081
    all_proxy=socks5h://127.0.0.1:1081
    ```
    
* stop-proxy: `. stop-proxy`
* chk-proxy: check value of environment variables: `http_proxy`, `https_proxy`, `ftp_proxy`, `all_porxy`
* swap two files/folders: `swap A/ B/`, `swap a.c b.c`

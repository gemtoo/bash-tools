#!/bin/bash

msg_ok() {
        printf "$(tput setaf 2)OK$(tput sgr 0)\n"
}
msg_err() {
        echo -e "$(tput setaf 1)$@$(tput sgr 0)"
}
die() {
        msg_err "$@"
        exit 1
}

OUR_IP=""

function what_is_my_ip() {
        echo "Sending a reuqest to determine our current public IP address ..."
        OUR_IP=$(curl -s 'https://ifconfig.me' || die "Failed to request from https://ifconfig.me")
        if [[ $IP =~ $IP_REGEX ]]; then
                echo "Success. Our IP is ${GRN}$OUR_IP${WHI}.${RST}"
        else
                die "An IP '${IP}' is not an IP address."
        fi
}
what_is_my_ip

# Парсим полный список всех доменных имён из конфигов. Не проверяются локации inactive-configs/, sample-configs/, а также не проверяется конфиг default.conf.
# Абсолютные пути указаны специально, т.к. скрипты через cron работают предсказуемо только с абсолютными путями.
DOMAINS=$(/usr/bin/grep -riIn "server_name" /etc/nginx/sites-available | /usr/bin/tr -s '[:space:]' | /usr/bin/cut -d ' ' -f3 | /usr/bin/sed "s/;//g;s/_//g" | xargs | sort | uniq)
# Исключения. Доменные имена не требующие SSL сертификата, например 301 редиректы, или то, что не работает без SSL, и т.п.
DOMAIN_EXCEPTIONS_THAT_DONT_NEED_SSL="sd.pixelartsoft.com servicedesk.pixelartsoft.com family-tree.vironit.com family-tree.pixelartsoft.com codeblue.vironitdev.com a-zshop.vironitdev.com a-zshop-web.vironitdev.com"

for DOMAIN in $DOMAINS; do
        # Если домен находится в списке исключений, дальнейшая процедура проверки и обновления сертификата пропускается.
        for DOMAIN_EXCEPTION in $DOMAIN_EXCEPTIONS_THAT_DONT_NEED_SSL; do
        # Поскольку это цикл внутри цикла, нам нужно пропустить этот + внешний цикл, поэтому continue 2.
                [[ "$DOMAIN_EXCEPTION" == "${DOMAIN}" ]] && continue 2
        done

        # Отправить запрос в DNS и спарсить полученный ответ в чистый IP адрес, затем сравнить его с переменной OUR_IP
        printf "\nChecking ${DOMAIN} points to "
        A_RECORD=$(/usr/bin/nslookup "${DOMAIN}" | /usr/bin/grep "Address:" | /usr/bin/tail -n 1 | /usr/bin/sed "s/Address: //")
        printf "${A_RECORD} "
        if [[ "${A_RECORD}" == "${OUR_IP}" ]]; then
                msg_ok
                /usr/bin/letsencrypt renew --cert-name "${DOMAIN}"
        else
                msg_err "ERR Domain ${DOMAIN} has a wrong A record that points to ${A_RECORD}. Skipping."
        fi
done

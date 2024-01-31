FROM nginx:latest

ARG DOMAIN_NAME

ARG IP_ADDRESS

COPY nginx.template /etc/nginx/conf.d/default.conf

RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
-keyout /etc/ssl/private/nginx-selfsigned.key \
-out /etc/ssl/certs/nginx-selfsigned.crt \
-subj "/CN=${DOMAIN_NAME}"

RUN sed -i -e "s/\${DOMAIN_NAME}/${DOMAIN_NAME}/" -e "s/\${IP_ADDRESS}/${IP_ADDRESS}/" /etc/nginx/conf.d/default.conf

RUN cat /etc/nginx/conf.d/default.conf

RUN nginx -t

CMD ["nginx", "-g", "daemon off;"]
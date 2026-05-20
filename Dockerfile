FROM nginx:alpine
COPY build/web /usr/share/nginx/html
RUN printf 'server {\n    listen ${PORT:-80};\n    root /usr/share/nginx/html;\n    index index.html;\n    location / {\n        try_files $uri $uri/ /index.html;\n    }\n}\n' > /etc/nginx/conf.d/default.conf
CMD sh -c "sed -i \"s/\${PORT:-80}/$PORT/g\" /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"

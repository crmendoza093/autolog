# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/stimulus", to: "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm"

pin_all_from "app/javascript/controllers", under: "controllers"

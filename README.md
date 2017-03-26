Минусы решения
==============

* Всё вот это в императивном стиле (Makefile) не устойчиво к внешним изменениями и внутренним косякам. Хорошим решением было бы собрать образ с уже готовым кластером и накатывать на него make.sql из Вашего репозитория. Другим хорошим решением было бы заменить императивный Makefile на декларативный ansible/puppet - это решит большую часть проблем которые безусловно возникнут в будущем.
* Налету патчатся конфиги, накатывается патч на репу. Это было бы хорошо зафиксировать а не патчить каждый раз

Плюсы решения
=============

* Makefile напишет каждый, быстро, mvp...

Минусы подхода
==============

* Postgresql внутри Docker не жизнеспособен на продакшине, по причине того что внутри контейнера нет такой метрики как фиксированная частота CPU и статистика набирается очень некорректно. Это приводит к неоптимальному поведению оптимизатора запросов и может привести к совсем неожиданным seqscan вместо поиска по индексам например, и подобным "неясным" на первый взгляд глюкам.
* Брать бинарные образы из открытых источников небезопасно, т.к. выполнить ревью образа глазами невозможно (он бинарь) и в итоге такой образ может стать прекрасным бекдором или просто дырой.
* Для start/stop контекнеров лучше использовать не Makefile (ибо велосипед), а например docker-compose (точкой доступа в который может быть тотже make start и make stop)

Плюсы подхода
=============

* в Makefile вотличие от bash нельзя забыть "set -e"
* Готовый образ docker под postgres решает вопрос времени развертки для test/dev сред
* Если postgres в докере планиурется для автотестов - то вполне пойдет и устроит



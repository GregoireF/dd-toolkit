# Politique de sécurité

## Ce que fait ce projet

Les scripts de `src/` envoient des touches clavier (via l'API Windows
`SendInput`) uniquement vers la fenêtre du processus configuré dans
`config/settings.ini` (`DunDefGame.exe` par défaut). Ils ne font aucun
accès réseau, ne collectent et n'envoient aucune donnée, et ne lisent pas
de fichiers en dehors de `config/settings.ini`.

## Signaler une vulnérabilité

S'il s'agit d'un problème sans impact tiers (bug de script, mauvais
scoping fenêtre, etc.), ouvre simplement une
[issue](../../issues) avec le template *Bug report*.

Pour un problème plus sensible (par exemple un `.exe` compilé qui se
comporterait différemment de son source `.ahk`), merci de ne pas poster
publiquement les détails d'exploitation et de contacter d'abord les
mainteneurs via une issue marquée comme confidentielle.

## Portée

Ce projet ne modifie ni ne contourne aucun mécanisme anti-triche. Le
tower stacking est une technique de jeu documentée et tolérée par la
communauté Dungeon Defenders (voir README) ; ce repo n'a pas vocation à
couvrir d'autres usages.

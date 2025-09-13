# Installation du Zephyr SDK

Ce guide explique comment installer le Zephyr SDK selon la documentation officielle pour utiliser avec ZMK.

## Installation automatique

### Option 1 : Via le Makefile (Recommandé)

```bash
# Installation complète avec SDK
make setup

# Ou installation des dépendances seulement
make install
```

### Option 2 : Via le script d'installation

```bash
# Installation complète
./scripts/install-deps.sh

# Ou SDK seulement (après avoir installé les autres dépendances)
./scripts/install-deps.sh --help
```

## Installation manuelle

Si l'installation automatique échoue, suivez ces étapes selon la [documentation officielle](https://docs.zephyrproject.org/latest/develop/toolchains/zephyr_sdk.html) :

### 1. Téléchargement

```bash
cd ~
# Pour x86_64 (Intel/AMD 64-bit)
wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.17.4/zephyr-sdk-0.17.4_linux-x86_64.tar.xz

# Pour ARM64 (Raspberry Pi, Apple Silicon via Linux VM, etc.)
wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.17.4/zephyr-sdk-0.17.4_linux-aarch64.tar.xz
```

### 2. Vérification d'intégrité (optionnel mais recommandé)

```bash
wget -O - https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.17.4/sha256.sum | shasum --check --ignore-missing
```

### 3. Extraction

```bash
# Pour x86_64
tar xvf zephyr-sdk-0.17.4_linux-x86_64.tar.xz

# Pour ARM64  
tar xvf zephyr-sdk-0.17.4_linux-aarch64.tar.xz
```

### 4. Configuration

```bash
cd zephyr-sdk-0.17.4
./setup.sh
```

### 5. Installation des règles udev (optionnel)

Pour pouvoir flasher les boards sans sudo :

```bash
sudo cp ~/zephyr-sdk-0.17.4/sysroots/x86_64-pokysdk-linux/usr/share/openocd/contrib/60-openocd.rules /etc/udev/rules.d
sudo udevadm control --reload
```

## Emplacements d'installation recommandés

Selon la documentation Zephyr, les meilleurs emplacements sont :

- `$HOME/zephyr-sdk-0.17.4` ⭐ **Recommandé**
- `$HOME/.local/zephyr-sdk-0.17.4`
- `$HOME/.local/opt/zephyr-sdk-0.17.4`
- `$HOME/bin/zephyr-sdk-0.17.4`
- `/opt/zephyr-sdk-0.17.4` (nécessite sudo)
- `/usr/local/zephyr-sdk-0.17.4` (nécessite sudo)

## Variables d'environnement

Après installation, ces variables peuvent être configurées :

```bash
# Automatique si installé dans un emplacement recommandé
export ZEPHYR_TOOLCHAIN_VARIANT=zephyr

# Seulement si installé dans un emplacement personnalisé
export ZEPHYR_SDK_INSTALL_DIR="$HOME/zephyr-sdk-0.17.4"
```

## Vérification de l'installation

```bash
# Via notre système de diagnostic
make diagnose

# Vérification manuelle
ls -la ~/zephyr-sdk-0.17.4/
arm-zephyr-eabi-gcc --version
```

## Versions supportées

- **Zephyr SDK 0.17.4** : Version recommandée pour Zephyr 3.5+ (utilisée par ZMK)
- **Zephyr SDK 0.16.x** : Compatible mais ancienne

## Architecture supportées

Le Zephyr SDK 0.17.4 supporte :

- **ARM** (32-bit et 64-bit) ⭐ **Nécessaire pour ZMK**
- ARC (32-bit et 64-bit)  
- RISC-V (32-bit et 64-bit)
- x86 (32-bit et 64-bit)
- MIPS (32-bit et 64-bit)
- Xtensa

## Dépannage

### Erreur "Could not find a package configuration file provided by Zephyr"

Cette erreur indique que le Zephyr SDK n'est pas correctement installé ou configuré.

**Solutions :**

1. Utiliser `make diagnose` pour identifier le problème
2. Réinstaller avec `make install`
3. Vérifier les variables d'environnement
4. S'assurer que le SDK est dans un emplacement recommandé

### SDK non détecté après installation

```bash
# Vérifier l'emplacement
ls -la ~/zephyr-sdk-*/

# Re-exécuter le setup
cd ~/zephyr-sdk-0.17.4
./setup.sh

# Vérifier la configuration
make diagnose
```

### Problèmes de permissions pour le flash

```bash
# Installer les règles udev
sudo cp ~/zephyr-sdk-0.17.4/sysroots/x86_64-pokysdk-linux/usr/share/openocd/contrib/60-openocd.rules /etc/udev/rules.d
sudo udevadm control --reload

# Ajouter l'utilisateur au groupe dialout (selon la distribution)
sudo usermod -a -G dialout $USER
# Puis redémarrer la session
```

## Liens utiles

- [Documentation officielle Zephyr SDK](https://docs.zephyrproject.org/latest/develop/toolchains/zephyr_sdk.html)
- [Releases Zephyr SDK](https://github.com/zephyrproject-rtos/sdk-ng/releases)
- [Matrice de compatibilité](https://github.com/zephyrproject-rtos/sdk-ng/wiki/Zephyr-Version-Compatibility)
- [Documentation ZMK](https://zmk.dev/docs/development/setup)

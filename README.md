# BetterBodyguards

FR : Script Lua Cherax pour faire spawn et contrôler des bodyguards qui te suivent, te protègent et combattent les ennemis.  
EN: Cherax Lua script to spawn and control bodyguards that follow you, protect you, and fight enemies.

---

## FR - Présentation

**BetterBodyguards** est un script Lua pour Cherax qui permet de :
- spawn 1, 5, 10 ou un nombre personnalisé de bodyguards
- choisir le modèle du bodyguard
- choisir son arme
- choisir un mode IA :
  - `Neutral`
  - `Defense`
  - `Offensive`
- faire suivre les bodyguards au joueur
- utiliser plusieurs formations
- protéger automatiquement le joueur
- faire entrer/sortir les bodyguards d’un véhicule
- afficher des blips
- activer l’auto respawn
- supprimer les bodyguards

---

## EN - Overview

**BetterBodyguards** is a Cherax Lua script that lets you:
- spawn 1, 5, 10, or a custom amount of bodyguards
- choose the bodyguard model
- choose the weapon
- choose an AI mode:
  - `Neutral`
  - `Defense`
  - `Offensive`
- make bodyguards follow the player
- use multiple formations
- automatically protect the player
- make bodyguards enter/exit a vehicle
- show blips
- enable auto respawn
- delete bodyguards

---

## FR - Fonctionnalités

### Spawn
- `Spawn 1`
- `Spawn 5`
- `Spawn 10`
- `Spawn Selected Amount`

### Modèles disponibles
- Security
- FIB
- IAA
- SWAT
- Black Ops

### Armes disponibles
- Pistol
- Combat Pistol
- SMG
- Carbine Rifle
- Pump Shotgun

### Modes IA
- **Neutral** : suit le joueur sans engager automatiquement
- **Defense** : attaque les ennemis hostiles qui ciblent le joueur
- **Offensive** : engage plus agressivement les cibles hostiles

### Formations
- Line
- Circle
- Around
- Triangle

### Actions
- Follow Player
- Protect Player
- Attack Nearby
- Teleport To Me
- Revive Missing
- Refresh All
- Delete Dead Only
- Delete All

### Véhicule
- Spawn In My Vehicle
- Enter My Vehicle
- Exit Vehicle
- Teleport To Vehicle

---

## EN - Features

### Spawn
- `Spawn 1`
- `Spawn 5`
- `Spawn 10`
- `Spawn Selected Amount`

### Available Models
- Security
- FIB
- IAA
- SWAT
- Black Ops

### Available Weapons
- Pistol
- Combat Pistol
- SMG
- Carbine Rifle
- Pump Shotgun

### AI Modes
- **Neutral**: follows the player without automatically engaging
- **Defense**: attacks hostile enemies targeting the player
- **Offensive**: engages hostile targets more aggressively

### Formations
- Line
- Circle
- Around
- Triangle

### Actions
- Follow Player
- Protect Player
- Attack Nearby
- Teleport To Me
- Revive Missing
- Refresh All
- Delete Dead Only
- Delete All

### Vehicle
- Spawn In My Vehicle
- Enter My Vehicle
- Exit Vehicle
- Teleport To Vehicle

---

## FR - Installation

1. Télécharge le fichier `BetterBodyguards.lua`
2. Place-le dans ton dossier de scripts Lua Cherax
3. Vérifie que le chemin des natives est correct dans le script :
   ```lua
   dofile("C:/Users/GarnalG/Documents/Cherax/Lua/DannyScript/Natives/natives.lua")

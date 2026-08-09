/*
**  cr_hud.ring - HUD, Title Screen & Overlay Functions
**  Code Rooms 3D
*/

func cr_drawHUD
    // Top bar background
    DrawRectangle(0, 0, SCREEN_W, 80, RAYLIBColor(15, 12, 25, 220))
    DrawRectangle(0, 80, SCREEN_W, 2, RAYLIBColor(80, 60, 140, 255))

    // Room number
    roomStr = "Room " + currentRoom + " / " + roomCount
    DrawText(roomStr, 20, 12, 20, RAYLIBColor(180, 160, 220, 255))

    // Room title
    DrawText(roomTitle, 20, 38, 24, RAYLIBColor(255, 220, 80, 255))

    // Hint: number of blocks to place
    hintStr = "Arrange " + slotCount + " blocks in the correct order"
    DrawText(hintStr, 20, 62, 14, RAYLIBColor(140, 200, 140, 200))

    // Right side - move count and controls
    mvStr = "Moves: " + moveCount
    mvW = MeasureText(mvStr, 18)
    DrawText(mvStr, SCREEN_W - mvW - 20, 12, 18, RAYLIBColor(200, 200, 220, 255))

    ctrlStr = "R:Restart  C:Camera  U:Undo"
    ctrlW = MeasureText(ctrlStr, 14)
    DrawText(ctrlStr, SCREEN_W - ctrlW - 20, 38, 14, RAYLIBColor(140, 140, 160, 200))

    camNames = ["Top-Down", "Angled", "Follow"]
    camStr = "Camera: " + camNames[camMode + 1]
    camSW = MeasureText(camStr, 14)
    DrawText(camStr, SCREEN_W - camSW - 20, 56, 14, RAYLIBColor(120, 160, 200, 200))

    // Bottom: Assembly line status
    cr_drawAssemblyHUD()

    // Block labels overlay (2D projected from 3D)
    cr_drawBlockLabels2D()

// =============================================================
// Assembly Line HUD (bottom bar)
// =============================================================

func cr_drawAssemblyHUD
    barH = 70
    barY = SCREEN_H - barH
    DrawRectangle(0, barY, SCREEN_W, barH, RAYLIBColor(15, 12, 25, 220))
    DrawRectangle(0, barY, SCREEN_W, 2, RAYLIBColor(80, 60, 140, 255))

    DrawText("Assembly Line:", 20, barY + 8, 16, RAYLIBColor(180, 160, 220, 255))

    // Draw slot boxes
    slotW = 80
    slotH = 36
    startX = 20
    sy = barY + 30

    for si = 1 to slotCount
        sx = startX + (si - 1) * (slotW + 6)
        expected = slots[si][3]
        filled = slots[si][4]
        fbi = slots[si][5]

        // Background
        if filled and fbi > 0 and blocks[fbi][3] = expected
            // Correct - green
            DrawRectangle(sx, sy, slotW, slotH, RAYLIBColor(40, 160, 60, 255))
            DrawText(blocks[fbi][3], sx + 4, sy + 10, 16, WHITE)
        but filled and fbi > 0
            // Wrong block - red
            DrawRectangle(sx, sy, slotW, slotH, RAYLIBColor(180, 50, 40, 255))
            DrawText(blocks[fbi][3], sx + 4, sy + 10, 16, WHITE)
        else
            // Empty slot
            DrawRectangle(sx, sy, slotW, slotH, RAYLIBColor(40, 50, 80, 255))
            numStr = "" + si
            DrawText(numStr, sx + slotW/2 - 4, sy + 10, 16, RAYLIBColor(100, 120, 150, 200))
        ok

        // Border
        DrawRectangleLines(sx, sy, slotW, slotH, RAYLIBColor(100, 80, 160, 255))
    next

// =============================================================
// Block Labels as 2D Projected Text
// =============================================================

func cr_drawBlockLabels2D
    for bi = 1 to blockCount
        bx = blocks[bi][4]
        bz = blocks[bi][5]
        label = blocks[bi][3]

        // Manual 3D to 2D projection
        sx = 0
        sy = 0
        cr_project3Dto2D(bx, 1.4, bz)
        sx = projSX
        sy = projSY

        if sx > 0 and sx < SCREEN_W and sy > 0 and sy < SCREEN_H
            tw = MeasureText(label, 18)
            bx2 = sx - tw / 2 - 4
            by2 = sy - 12

            // Background
            DrawRectangle(bx2, by2, tw + 8, 22, RAYLIBColor(20, 15, 30, 200))
            DrawRectangleLines(bx2, by2, tw + 8, 22, RAYLIBColor(140, 120, 180, 200))

            // Text
            DrawText(label, bx2 + 4, by2 + 3, 18, RAYLIBColor(255, 240, 200, 255))
        ok
    next

// =============================================================
// 3D to 2D Projection (manual - struct access workaround)
// =============================================================

func cr_project3Dto2D wx, wy, wz
    // Get camera vectors
    cpx = cam.position.x
    cpy = cam.position.y
    cpz = cam.position.z
    ctx = cam.target.x
    cty = cam.target.y
    ctz = cam.target.z

    // Forward vector
    fx = ctx - cpx
    fy = cty - cpy
    fz = ctz - cpz
    fl = sqrt(fx*fx + fy*fy + fz*fz)
    if fl < 0.001 fl = 0.001 ok
    fx = fx / fl  fy = fy / fl  fz = fz / fl

    // Right vector (cross with up)
    ux = 0  uy = 1  uz = 0
    rx = fy * uz - fz * uy
    ry = fz * ux - fx * uz
    rz = fx * uy - fy * ux
    rl = sqrt(rx*rx + ry*ry + rz*rz)
    if rl < 0.001 rl = 0.001 ok
    rx = rx / rl  ry = ry / rl  rz = rz / rl

    // Recalc up
    ux2 = ry * fz - rz * fy
    uy2 = rz * fx - rx * fz
    uz2 = rx * fy - ry * fx

    // Point relative to camera
    dx = wx - cpx
    dy = wy - cpy
    dz = wz - cpz

    // View coords
    vx = dx * rx + dy * ry + dz * rz
    vy = dx * ux2 + dy * uy2 + dz * uz2
    vz = dx * fx + dy * fy + dz * fz

    if vz < 0.1
        projSX = -1000
        projSY = -1000
        return
    ok

    // Perspective
    fov = cam.fovy
    tanHalf = cr_tan(fov * 0.5 * 3.14159 / 180)
    aspect = SCREEN_W / SCREEN_H

    projSX = floor(SCREEN_W / 2 + (vx / (vz * tanHalf * aspect)) * SCREEN_W / 2)
    projSY = floor(SCREEN_H / 2 - (vy / (vz * tanHalf)) * SCREEN_H / 2)

// =============================================================
// Title Screen
// =============================================================

// =============================================================
// Solved Overlay
// =============================================================

func cr_drawSolvedOverlay
    DrawRectangle(0, 0, SCREEN_W, SCREEN_H, RAYLIBColor(0, 0, 0, 80))

    t1 = "PUZZLE SOLVED!"
    t1w = MeasureText(t1, 48)
    DrawText(t1, (SCREEN_W - t1w) / 2, SCREEN_H / 2 - 60, 48,
             RAYLIBColor(50, 255, 80, 255))

    t2 = "Door is opening..."
    t2w = MeasureText(t2, 22)
    DrawText(t2, (SCREEN_W - t2w) / 2, SCREEN_H / 2, 22,
             RAYLIBColor(200, 220, 255, 255))

// =============================================================
// Win Screen
// =============================================================

func cr_drawWinScreen
    DrawRectangle(0, 0, SCREEN_W, SCREEN_H, RAYLIBColor(0, 0, 0, 160))

    t1 = "CONGRATULATIONS!"
    t1w = MeasureText(t1, 52)
    DrawText(t1, (SCREEN_W - t1w) / 2, SCREEN_H / 2 - 100, 52,
             RAYLIBColor(255, 215, 0, 255))

    t2 = "You escaped all " + roomCount + " rooms!"
    t2w = MeasureText(t2, 28)
    DrawText(t2, (SCREEN_W - t2w) / 2, SCREEN_H / 2 - 30, 28,
             RAYLIBColor(200, 220, 255, 255))

    t3 = "Total Moves: " + moveCount
    t3w = MeasureText(t3, 22)
    DrawText(t3, (SCREEN_W - t3w) / 2, SCREEN_H / 2 + 20, 22,
             RAYLIBColor(180, 200, 220, 255))

    t4 = "A true programmer escapes any trap!"
    t4w = MeasureText(t4, 20)
    DrawText(t4, (SCREEN_W - t4w) / 2, SCREEN_H / 2 + 70, 20,
             RAYLIBColor(255, 220, 80, 220))

    t5 = "Press ENTER to play again  |  ESC to exit"
    t5w = MeasureText(t5, 20)
    pulse = floor(180 + 75 * sin(animTime * 3.0))
    if pulse > 255 pulse = 255 ok
    DrawText(t5, (SCREEN_W - t5w) / 2, SCREEN_H / 2 + 130, 20,
             RAYLIBColor(160, 220, 255, pulse))

// =============================================================
// Combined Welcome + Room-Select Screen
// =============================================================

# Decorative gradient border frame around the welcome screen, in the style of
# povc.ring's notification borders (drawFancyBorder) but drawn with plain
# raylib primitives instead of the border PNG.
func drawScreenBorder gradCol1, gradCol2, outerCol, innerCol
    inset = 14   thick = 5
    DrawRectangleGradientH(inset, inset, SCREEN_W-inset*2, thick, gradCol1, gradCol2)
    DrawRectangleGradientH(inset, SCREEN_H-inset-thick, SCREEN_W-inset*2, thick, gradCol2, gradCol1)
    DrawRectangleGradientV(inset, inset, thick, SCREEN_H-inset*2, gradCol1, gradCol2)
    DrawRectangleGradientV(SCREEN_W-inset-thick, inset, thick, SCREEN_H-inset*2, gradCol1, gradCol2)
    DrawRectangleLines(inset-3, inset-3, SCREEN_W-(inset-3)*2, SCREEN_H-(inset-3)*2, outerCol)
    DrawRectangleLines(inset+thick+4, inset+thick+4, SCREEN_W-(inset+thick+4)*2, SCREEN_H-(inset+thick+4)*2, innerCol)

# Shared layout math for the combined welcome/room-select screen, used by
# both cr_drawMenu (drawing) and cr_handleMenuInput (mouse hit-testing) so
# they can never drift apart. Fonts scale with the monitor's actual
# resolution (baseline = 700px tall), and the whole block -- title, subtitle,
# guidelines, room grid, close button -- is vertically centered based on its
# real computed content height.
func cr_computeMenuLayout
    mY = SCREEN_H / 700.0

    cr_titleSz = max(40, floor(100*mY))
    cr_subSz   = max(18, floor(36*mY))
    cr_ctrlSz  = max(12, floor(20*mY))
    cr_selLblSz= max(15, floor(28*mY))

    cr_roomLblSz = max(18, floor(28*mY))
    cr_btnLblSz = max(15, floor(22*mY))
    cr_btnW = max(floor(100*mY), MeasureText("CLOSE GAME", cr_btnLblSz) + 30)
    cr_btnH = floor(50*mY)

    cr_cardW = max(floor(90*mY), MeasureText("10", cr_roomLblSz) + 30)
    cr_cardH = cr_btnH        // same height as the Close button
    cr_gapX  = floor(20*mY)
    cr_gapY  = floor(18*mY)

    gap1 = floor(14*mY)   // title -> subtitle
    gap2 = floor(16*mY)   // subtitle -> controls
    ctrlPitch = floor(26*mY)
    gap3 = floor(20*mY)   // controls -> "SELECT ROOM" label
    gap4 = floor(12*mY)   // label -> grid
    gap5 = floor(16*mY)   // grid -> close button

    titleBlockH = cr_titleSz + floor(14*mY)
    subBlockH   = cr_subSz
    ctrlBlockH  = ctrlPitch + cr_ctrlSz   // 2 lines
    selLblBlockH = cr_selLblSz
    cr_gridH = 2 * cr_cardH + cr_gapY
    btnBlockH = cr_btnH

    contentH = titleBlockH+gap1+subBlockH+gap2+ctrlBlockH+gap3+selLblBlockH+gap4+cr_gridH+gap5+btnBlockH

    topY = floor((SCREEN_H - contentH) / 2)
    if topY < floor(14*mY)  topY = floor(14*mY)  ok

    cr_titleY   = topY
    cr_subY     = cr_titleY + titleBlockH + gap1
    cr_ctrlY1   = cr_subY + subBlockH + gap2
    cr_ctrlY2   = cr_ctrlY1 + ctrlPitch
    cr_selLblY  = cr_ctrlY1 + ctrlBlockH + gap3
    cr_startY   = cr_selLblY + selLblBlockH + gap4
    cr_btnY     = cr_startY + cr_gridH + gap5

    totalGridW = 5 * cr_cardW + 4 * cr_gapX
    cr_startX = floor((SCREEN_W - totalGridW) / 2)
    cr_btnX   = floor((SCREEN_W - cr_btnW) / 2)

func cr_drawMenu
    cr_computeMenuLayout()

    // Menu background image
    DrawTexturePro(cr_menuBackTex,
        Rectangle(0.0, 0.0, cr_menuBackTex.width*1.0, cr_menuBackTex.height*1.0),
        Rectangle(0.0, 0.0, SCREEN_W*1.0, SCREEN_H*1.0),
        Vector2(0.0, 0.0), 0.0, WHITE)

    // Title (with a gentle wobble/bounce, drop-shadow copy underneath)
    wob = floor(sin(animTime * 2.0) * 8)
    t1 = "Code Rooms 3D"
    t1w = MeasureText(t1, cr_titleSz)
    DrawText(t1, floor((SCREEN_W - t1w)/2) + 3, cr_titleY + 3 + wob, cr_titleSz, RAYLIBColor(0, 20, 10, 200))
    DrawText(t1, floor((SCREEN_W - t1w)/2), cr_titleY + wob, cr_titleSz, WHITE)

    // Subtitle
    sub = "Programming Puzzle Game"
    DrawText(sub, floor((SCREEN_W - MeasureText(sub, cr_subSz)) / 2), cr_subY,
             cr_subSz, RAYLIBColor(180, 220, 180, 200))

    ctrl1 = "Push code blocks onto the assembly line to solve each room!"
    DrawText(ctrl1, floor((SCREEN_W - MeasureText(ctrl1, cr_ctrlSz)) / 2), cr_ctrlY1,
             cr_ctrlSz, RAYLIBColor(180, 220, 180, 200))

    ctrl2 = "Arrows/WASD: Move & Push  |  U: Undo  |  R: Restart  |  C: Camera"
    DrawText(ctrl2, floor((SCREEN_W - MeasureText(ctrl2, cr_ctrlSz)) / 2), cr_ctrlY2,
             cr_ctrlSz, RAYLIBColor(180, 220, 180, 200))

    selLabel = "SELECT ROOM"
    DrawText(selLabel, floor((SCREEN_W - MeasureText(selLabel, cr_selLblSz)) / 2),
             cr_selLblY, cr_selLblSz, RAYLIBColor(180, 220, 180, 200))

    cols = 5
    cardW = cr_cardW  cardH = cr_cardH
    gapX  = cr_gapX   gapY  = cr_gapY
    startX = cr_startX  startY = cr_startY

    for i = 1 to roomCount
        row = floor((i - 1) / cols)
        col = (i - 1) % cols
        cx  = startX + col * (cardW + gapX)
        cy  = startY + row * (cardH + gapY)

        isActive   = (i = menuSelectedLevel)

        if isActive
            DrawRectangleGradientV(cx, cy, cardW, cardH, RAYLIBColor(210, 235, 248, 255), RAYLIBColor(140, 190, 218, 255))
            DrawRectangleLines(cx, cy, cardW, cardH, RAYLIBColor(0, 0, 80, 255))
            cardTextCol = RAYLIBColor(0, 0, 80, 255)
        else
            DrawRectangleGradientV(cx, cy, cardW, cardH, RAYLIBColor(25, 35, 45, 255), RAYLIBColor(12, 18, 25, 255))
            DrawRectangleLines(cx, cy, cardW, cardH, RAYLIBColor(173, 216, 230, 255))
            cardTextCol = RAYLIBColor(173, 216, 230, 255)
        ok

        // Room number
        roomStr = string(i)
        rW      = MeasureText(roomStr, cr_roomLblSz)
        DrawText(roomStr, cx + floor((cardW - rW) / 2), cy + floor((cardH - cr_roomLblSz) / 2), cr_roomLblSz, cardTextCol)
    next

    // Close button
    btnW = cr_btnW  btnH = cr_btnH
    btnX = cr_btnX  btnY = cr_btnY

    btnActive = (menuSelectedLevel = CLOSE_BTN)
    if btnActive
        DrawRectangleGradientV(btnX, btnY, btnW, btnH, RAYLIBColor(210, 235, 248, 255), RAYLIBColor(140, 190, 218, 255))
        DrawRectangleLines(btnX, btnY, btnW, btnH, RAYLIBColor(0, 0, 80, 255))
        btnTextCol = RAYLIBColor(0, 0, 80, 255)
    else
        DrawRectangleGradientV(btnX, btnY, btnW, btnH, RAYLIBColor(25, 35, 45, 255), RAYLIBColor(12, 18, 25, 255))
        DrawRectangleLines(btnX, btnY, btnW, btnH, RAYLIBColor(173, 216, 230, 255))
        btnTextCol = RAYLIBColor(173, 216, 230, 255)
    ok
    closeStr = "CLOSE GAME"
    DrawText(closeStr, btnX + floor((btnW - MeasureText(closeStr, cr_btnLblSz)) / 2),
             btnY + floor((btnH - cr_btnLblSz) / 2), cr_btnLblSz, btnTextCol)

    drawScreenBorder(RAYLIBColor(8,60,30,235), RAYLIBColor(3,25,12,235), RAYLIBColor(173,216,230,255), RAYLIBColor(173,216,230,70))


import { defineConfig } from "prisma/config";
// La generación no conecta ni aplica cambios. SQL de creación/población sigue siendo canónico.
export default defineConfig({ schema: "prisma/schema.prisma" });

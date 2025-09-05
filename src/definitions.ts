export interface MultiCameraPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}

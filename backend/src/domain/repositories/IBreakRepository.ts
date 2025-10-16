import { Break } from '../entities/Break';

export interface IBreakRepository {
  create(breakEntity: Break): Promise<Break>;
  findById(id: string): Promise<Break | null>;
  findBySessionId(sessionId: string): Promise<Break[]>;
  update(breakEntity: Break): Promise<Break>;
  delete(id: string): Promise<void>;
}
